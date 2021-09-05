const { ProgramRunner } = require('elm-spec-core')

module.exports = class HarnessRunner extends ProgramRunner {
  handleMessage(specMessage, out) {
    switch (specMessage.home) {
      case "_harness":
        this.handleHarnessEvent(specMessage, out)
        break
      default:
        super.handleMessage(specMessage, out)
    }
  }

  handleHarnessEvent(specMessage, out) {
    switch (specMessage.name) {
      // Maybe here we need to do something that tells the port plugin to unsubscribe?
      case "complete":
        this.emit("complete", true)
        break
      case "abort":
        this.emit("error", specMessage.body)
        break
    }
  }
}