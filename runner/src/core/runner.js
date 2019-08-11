const EventEmitter = require('events')
const PortPlugin = require('./portPlugin')
const TimePlugin = require('./timePlugin')

module.exports = class Core extends EventEmitter {
  constructor(app) {
    super()
    this.app = app
    this.timer = null
    this.portPlugin = new PortPlugin(app)
    this.timePlugin = new TimePlugin()
  }

  run() {
    this.app.ports.sendOut.subscribe((specMessage) => {
      try {
        switch (specMessage.home) {
          case "_spec":
            this.handleLifecycleEvent(specMessage)
            break
          case "_port":
            this.portPlugin.handle(specMessage)
            break
          case "_time":
            this.timePlugin.handle(specMessage)
            break
          default:
            console.log("Unknown message:", specMessage)
            break
        }
      } catch (err) {
        this.emit('error', err)
      }
    })
  }

  handleLifecycleEvent(specMessage) {
    switch (specMessage.name) {
      case "state":
        this.handleStateChange(specMessage.body)
        break
      case "observation":
        this.emit('observation', specMessage.body)
        break
    }
  }

  handleStateChange(state) {
    switch (state) {
      case "CONFIGURE_COMPLETE":
        setTimeout(() => {
          this.app.ports.sendIn.send({ home: "_spec", name: "state", body: "START_STEPS" })
        }, 0)
        break
      case "STEP_COMPLETE":
        if (this.timer) clearTimeout(this.timer)
        this.timer = setTimeout(() => {
          this.app.ports.sendIn.send({ home: "_spec", name: "state", body: "NEXT_STEP" })
        }, 1)
        break
      case "OBSERVATIONS_COMPLETE":
        setTimeout(() => {
          this.timePlugin.reset()
          this.app.ports.sendIn.send({ home: "_spec", name: "state", body: "NEXT_SPEC" })
        }, 0)
        break
      case "SPEC_COMPLETE":
        this.emit('complete')
        break
    }
  }
}