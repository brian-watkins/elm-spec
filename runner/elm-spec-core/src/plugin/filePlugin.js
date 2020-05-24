const { report, line } = require('../report')
const BlobReader = require('../blobReader')

module.exports = class FilePlugin {
  constructor(context) {
    this.window = context.window
    this.context = context
    this.out = this.context.sendToProgram()
    this.reset()
  }

  reset() {
    this.context.mapElement(element => this.decorateElement(element))
  }

  decorateElement(element) {
    switch (element.tagName) {
      case "INPUT":
        element.addEventListener("click", (evt) => this.inputClickHandler(evt))
        break
      case "A":
        element.addEventListener("click", (evt) => this.anchorClickHandler(evt))
        break
    }

    return element
  }

  inputClickHandler(event) {
    const inputElement = event.target
    if (inputElement.type === "file") {
      this.context.openFileSelector(inputElement)
      event.preventDefault()
    }
  }

  anchorClickHandler(event) {
    const downloadElement = event.target
    if (downloadElement.attributes.getNamedItem("download")) {
      const downloadUrl = new URL(downloadElement.href)

      if (downloadUrl.protocol === "blob:") {
        this.recordBlobDownload(downloadUrl, downloadElement.download)
      } else {
        this.recordUrlDownload(downloadUrl, downloadElement.download)
      }

      event.preventDefault()
    }
  }

  recordDownload(name, content) {
    this.out({
      home: "_file",
      name: "download",
      body: {
        name,
        content
      }
    })
  }

  recordBlobDownload(blobUrl, filename) {
    const blobKey = blobUrl.pathname.split("/").pop()
    const blob = this.context.blobStore().get(blobKey)
    new BlobReader(blob).readIntoArray()
      .then((data) => {
        this.context.timer.releaseHold()
        this.recordDownload(filename, { type: "bytes", data })
      })
    this.context.timer.requestHold()
  }

  recordUrlDownload(url, downloadName) {
    const filename = downloadName === "" ? url.pathname.split("/").pop() : downloadName
    this.recordDownload(filename, { type: "fromUrl", url: url.toString() })
  }

  handle(specMessage, out, next, abort) {
    switch (specMessage.name) {
      case "fetch": {
        Promise.all(specMessage.body.fileFixtures.map(fixture => this.fetchFile(fixture)))
          .then(files => {
            out({
              home: "_file",
              name: "file",
              body: files
            })
          })
          .catch((error) => {
            switch (error.type) {
              case "file":
                abort(this.fileReadError(error.path))
                break
              default:
                abort(this.missingLoadFileCapabilityError())
            }
          })

        break
      }
      case "select": {
        const fileInput = this.context.fileInputForOpenFileSelector()

        if (!fileInput) {
          abort(this.noOpenFileSelectorError())
          return
        }

        const fileInputWithFiles = Object.defineProperty(fileInput, "files", {
          value: specMessage.body.files,
          writable: true
        })

        fileInputWithFiles.dispatchEvent(this.getEvent("change"))  
  
        break
      }
      default:
        console.log("unknown file message", specMessage)
    }
  }

  fetchFile(fixture) {
    switch (fixture.content.type) {
      case "disk":
        return this.context.readBytesFromFile(fixture.path)
          .then(({ path, buffer }) => {
            const bytes = new Uint8Array(buffer.data)
            return new File([bytes], path, {
              type: fixture.mimeType,
              lastModified: fixture.lastModified || Date.now()
            })
          })
      case "memory":
        const file = new File([Uint8Array.from(fixture.content.bytes)], fixture.path, {
          type: fixture.mimeType,
          lastModified: fixture.lastModified || Date.now()
        })
        return Promise.resolve(file)
    }
  }

  getEvent(name, options = {}) {
    const details = Object.assign({ bubbles: true, cancelable: true }, options)
    return new Event(name, details)
  }

  noOpenFileSelectorError() {
    return report(
      line("No open file selector!", "Either click an input element of type file or otherwise take action so that a File.Select.file(s) command is sent by the program under test.")
    )
  }

  missingLoadFileCapabilityError() {
    return report(
      line("An attempt was made to load a file from disk, but this runner does not support that capability."),
      line("If you need to load a file from disk, consider using the standard elm-spec runner.")
    )
  }

  fileReadError(path) {
    return report(
      line("Unable to read file at", path)
    )
  }
}