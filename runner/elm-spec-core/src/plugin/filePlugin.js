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
        BrowserContext.readFile(this.window, specMessage.body.path)
          .then(({ path, buffer }) => {
            const bytes = new Uint8Array(buffer.data)
            out({
              home: "_file",
              name: "file",
              body: new File([bytes], path)
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
        const file = specMessage.body.file
        const fileInput = fileInputForOpenFileSelector(this.window)

        if (!fileInput) {
          abort(this.noOpenFileSelectorError())
          return
        }

        const fileInputWithFiles = Object.defineProperty(fileInput, "files", {
          value: [file],
          writable: true
        })

        fileInputWithFiles.dispatchEvent(this.getEvent("change"))  
  
        break
      }
      default:
        console.log("unknown file message", specMessage)
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