const { report, line } = require('../report')
const { fileInputForOpenFileSelector } = require('../fakes')
const BrowserContext = require("../browserContext")

module.exports = class FilePlugin {
  constructor(context) {
    this.window = context.window
    this.context = context
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
    return BrowserContext.readFile(this.window, fixture.path)
      .then(({ path, buffer }) => {
        const bytes = new Uint8Array(buffer.data)
        return new File([bytes], path)
      })
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