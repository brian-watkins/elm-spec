const { report, line } = require('../report')
const {
  fileInputForOpenFileSelector,
  mapElement,
  blobStore,
  openFileSelector,
  sendToProgram
} = require('../fakes')
const BrowserContext = require("../browserContext")
const BlobReader = require('../blobReader')

module.exports = class FilePlugin {
  constructor(context) {
    this.window = context.window
    this.context = context
    this.out = sendToProgram(this.window)
    this.reset()
  }

  reset() {
    mapElement(element => this.decorateElement(element))
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
      openFileSelector(this.window, inputElement)
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
    const blob = blobStore().get(blobKey)
    new BlobReader(blob).readIntoArray()
      .then((data) => {
        this.recordDownload(filename, { type: "bytes", data })
      })
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
          .catch(({ path }) => {
            abort(report(
              line("Unable to read file at", path)
            ))
          })

        break
      }
      case "select": {
        const fileInput = fileInputForOpenFileSelector(this.window)

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
    switch (fixture.type) {
      case "disk":
        return BrowserContext.readFile(this.window, fixture.path)
          .then(({ path, buffer }) => {
            const bytes = new Uint8Array(buffer.data)
            return new File([bytes], path)
          })
      case "memory":
        const file = new File([Uint8Array.from(fixture.bytes)], fixture.path)
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
}