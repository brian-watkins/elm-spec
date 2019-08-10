const EventEmitter = require('events')
const PortPlugin = require('./portPlugin')

module.exports = class Core extends EventEmitter {
  constructor(app) {
    super()
    this.app = app
    this.timer = null
  }

  run() {
    const portPlugin = new PortPlugin(this.app)
  
    this.app.ports.sendOut.subscribe((specMessage) => {
      try {
        switch (specMessage.home) {
          case "_spec":
            this.handleLifecycleEvent(specMessage)
            break;
          case "_port":
            portPlugin.handle(specMessage)
            break;
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
      case "STEP_COMPLETE":
        if (this.timer) clearTimeout(this.timer)
        this.timer = setTimeout(() => {
          this.app.ports.sendIn.send({ home: "_spec", name: "state", body: "NEXT_STEP" })
        }, 1)
        break
      case "SPEC_COMPLETE":
        this.emit('complete')
        break
    }
  }
}