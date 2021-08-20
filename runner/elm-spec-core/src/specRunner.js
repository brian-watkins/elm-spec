const ProgramRunner = require('./programRunner')

const ELM_SPEC_PICK = "elmSpecPick"

module.exports = class SpecRunner extends ProgramRunner {
  run() {
    this.stopHandlingMessages = super.run()

    setTimeout(() => {
      this.startSpecs()
    }, 0)
  }

  startSpecs() {
    const tags = this.app.ports[ELM_SPEC_PICK] ? [ "_elm_spec_pick" ] : []
    this.app.ports["elmSpecIn"].send(this.specStateMessage("start", { tags }))
  }

  handleMessage(specMessage, out) {
    switch (specMessage.home) {
      case "_spec":
        this.handleSpecEvent(specMessage)
        break
      default:
        super.handleMessage(specMessage, out)
    }
  }

  handleSpecEvent(specMessage) {
    switch (specMessage.name) {
      case "state": {
        switch (specMessage.body) {
          case "COMPLETE": {
            this.context.clearElementMappers()
            this.emit('complete', true)
            break
          }
          case "FINISHED": {
            this.emit('complete', false)
            break
          }
        }
        break    
      }
      case "error": {
        this.stopHandlingMessages()
        this.emit('error', specMessage.body)
        break
      }
    }
  }
}