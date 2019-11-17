const EventEmitter = require('events')
const PortPlugin = require('./plugin/portPlugin')
const TimePlugin = require('./plugin/timePlugin')
const HtmlPlugin = require('./plugin/htmlPlugin')
const HttpPlugin = require('./plugin/httpPlugin')
const { registerApp, setBaseLocation } = require('./fakes')

module.exports = class ProgramRunner extends EventEmitter {
  constructor(app, context, options) {
    super()
    this.app = app
    this.context = context
    this.timer = null
    this.portPlugin = new PortPlugin(app)
    this.timePlugin = new TimePlugin(this.context.clock, this.context.window)
    this.plugins = this.generatePlugins(this.context)
    this.options = options

    registerApp(this.app, this.context.window)
  }

  generatePlugins(context) {
    return {
      "_html": new HtmlPlugin(context),
      "_http": new HttpPlugin(context)
    }
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

    this.timePlugin.nativeSetTimeout(() => {
      this.app.ports.sendIn.send({ home: "_spec", name: "state", body: "START" })
    }, 0)
  }

  handleMessage(specMessage, out) {
    switch (specMessage.home) {
      case "_spec":
        this.handleSpecEvent(specMessage)
        break
      case "_scenario":
        this.handleScenarioEvent(specMessage, out)
        break
      case "_port":
        this.portPlugin.handle(specMessage, this.sendAbortMessage(out))
        break
      case "_time":
        this.timePlugin.handle(specMessage, () => {
          this.handleMessage({home: "_scenario", name: "state", body: "STEP_COMPLETE"}, out)
        })
        break
      case "_witness":
        out(specMessage)
        break
      case "_observer":
        this.stopTimeoutTimer()
        this.handleObserverEvent(specMessage, out)
        break
      default:
        const plugin = this.plugins[specMessage.home]
        if (plugin) {
          plugin.handle(specMessage, out, this.sendAbortMessage(out))
        } else {
          console.log("Message for unknown plugin:", specMessage)
        }
        break
    }
  }

  sendAbortMessage(out) {
    return (reason) => {
      out({ home: "_scenario", name: "abort", body: reason})
    }
  }

  handleObserverEvent(specMessage, out) {
    switch (specMessage.name) {
      case "inquiry":
        const inquiry = specMessage.body.message
        this.handleMessage(inquiry, (message) => {
          out({
            home: "_observer",
            name: "inquiryResult",
            body: {
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

  handleSpecEvent(specMessage) {
    switch (specMessage.body) {
      case "COMPLETE":
        this.timePlugin.resetFakes()
        this.emit('complete')
        break  
    }
  }

  handleScenarioEvent(specMessage, out) {
    switch (specMessage.name) {
      case "state":
        this.handleStateChange(specMessage.body, out)
        break
    }
  }

  handleStateChange(state, out) {
    switch (state) {
      case "START":
        this.prepareForScenario()
        this.startTimeoutTimer(out)
        out(this.continue())
        break
      case "CONFIGURE_COMPLETE":
        out(this.continue())
        break
      case "STEP_COMPLETE":
        if (this.timer) clearTimeout(this.timer)
        this.timer = this.timePlugin.nativeSetTimeout(() => {
          out(this.continue())
        }, 0)
        this.startTimeoutTimer(out)
        break
    }
  }

  prepareForScenario() {
    this.timePlugin.clearTimers()
    setBaseLocation("http://elm-spec", this.context.window)
  }

  startTimeoutTimer(out) {
    this.stopTimeoutTimer()
    this.scenarioTimeout = this.timePlugin.nativeSetTimeout(() => {
      out({
        home: "_scenario",
        name: "abort",
        body: [
          { statement: `Scenario timeout of ${this.options.timeout}ms exceeded!`,
            detail: null
          }
        ]
      })
    }, this.options.timeout)
  }

  stopTimeoutTimer() {
    if (this.scenarioTimeout) clearTimeout(this.scenarioTimeout)
  }

  continue () {
    return {
      home: "_scenario",
      name: "state",
      body: "CONTINUE"
    }
  }
}