const EventEmitter = require('events')
const PortPlugin = require('./portPlugin')
const TimePlugin = require('./timePlugin')

module.exports = class ProgramRunner extends EventEmitter {
  constructor(app, plugins) {
    super()
    this.app = app
    this.timer = null
    this.portPlugin = new PortPlugin(app)
    this.timePlugin = new TimePlugin()
    this.plugins = plugins
  }

  run() {
    this.app.ports.sendOut.subscribe((specMessage) => {
      try {
        this.handleMessage(specMessage, (outMessage) => {
          this.app.ports.sendIn.send(outMessage)
        })
      } catch (err) {
        this.emit('error', err)
      }
    })

    setTimeout(() => {
      this.app.ports.sendIn.send({ home: "_spec", name: "state", body: "START" })
    }, 0)
  }

  handleMessage(specMessage, out) {
    switch (specMessage.home) {
      case "_spec":
        this.handleLifecycleEvent(specMessage, out)
        break
      case "_port":
        this.portPlugin.handle(specMessage)
        break
      case "_time":
        this.timePlugin.handle(specMessage, () => {
          this.handleMessage({home: "_spec", name: "state", body: "STEP_COMPLETE"}, out)
        })
        break
      case "_witness":
        out(specMessage)
        break
      case "_observer":
        this.handleObserverEvent(specMessage, out)
        break
      default:
        const plugin = this.plugins[specMessage.home]
        if (plugin) {
          plugin.handle(specMessage, out, this.sendAbortMessage(out))
        } else {
          console.log("Unknown message:", specMessage)
        }
        break
    }
  }

  sendAbortMessage(out) {
    return (reason) => {
      out({ home: "_spec", name: "abort", body: reason})
    }
  }

  handleObserverEvent(specMessage, out) {
    switch (specMessage.name) {
      case "inquiry":
        const key = specMessage.body.key
        const inquiry = specMessage.body.message
        this.handleMessage(inquiry, (message) => {
          out({
            home: "_observer",
            name: "inquiryResult",
            body: {
              key,
              message
            }
          })
        })
        break
      case "observation":
        this.emit('observation', specMessage.body)
        out(this.continue())
        break
    }
  }

  handleLifecycleEvent(specMessage, out) {
    switch (specMessage.name) {
      case "state":
        this.handleStateChange(specMessage.body, out)
        break
    }
  }

  handleStateChange(state, out) {
    switch (state) {
      case "CONFIGURE_COMPLETE":
        out(this.continue())
        break
      case "STEP_COMPLETE":
        if (this.timer) clearTimeout(this.timer)
        this.timer = setTimeout(() => {
          out(this.continue())
        }, 0)
        break
      case "OBSERVATIONS_COMPLETE":
        this.timePlugin.reset()
        out(this.continue())
        break
      case "SPEC_COMPLETE":
        this.emit('complete')
        break
    }
  }

  continue () {
    return {
      home: "_spec",
      name: "state",
      body: "NEXT"
    }
  }
}