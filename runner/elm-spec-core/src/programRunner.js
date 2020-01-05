const EventEmitter = require('events')
const PortPlugin = require('./plugin/portPlugin')
const TimePlugin = require('./plugin/timePlugin')
const HtmlPlugin = require('./plugin/htmlPlugin')
const HttpPlugin = require('./plugin/httpPlugin')
const WitnessPlugin = require('./plugin/witnessPlugin')
const { registerApp, setBaseLocation, clearTimers, setTimezoneOffset } = require('./fakes')
const { report, line } = require('./report')

module.exports = class ProgramRunner extends EventEmitter {
  static hasElmSpecPorts(app) {
    if (!app.ports.hasOwnProperty("elmSpecOut")) {
      return report(
        line("No elmSpecOut port found!"),
        line("Make sure your elm-spec program uses a port defined like so", "port elmSpecOut : Message -> Cmd msg")
      )
    }

    if (!app.ports.hasOwnProperty("elmSpecIn")) {
      return report(
        line("No elmSpecIn port found!"),
        line("Make sure your elm-spec program uses a port defined like so", "port elmSpecIn : (Message -> msg) -> Sub msg")
      )
    }

    return null
  }

  constructor(app, context, options) {
    super()
    this.app = app
    this.context = context
    this.timer = null
    this.portPlugin = new PortPlugin(app)
    this.plugins = this.generatePlugins(this.context)
    this.options = options

    registerApp(this.app, this.context.window)
  }

  generatePlugins(context) {
    return {
      "_html": new HtmlPlugin(context),
      "_http": new HttpPlugin(context),
      "_time": new TimePlugin(context),
      "_witness": new WitnessPlugin(),
      "_port": this.portPlugin
    }
  }

  run() {
    const messageHandler = (specMessage) => {
      this.handleMessage(specMessage, (outMessage) => {
        this.app.ports.elmSpecIn.send(outMessage)
      })
    }

    this.app.ports.elmSpecOut.subscribe(messageHandler)
    this.stopHandlingMessages = () => { this.app.ports.elmSpecOut.unsubscribe(messageHandler) }

    setTimeout(() => {
      this.app.ports.elmSpecIn.send(this.specStateMessage("START"))
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
      case "_observer":
        this.handleObserverEvent(specMessage, out)
        break
      default:
        const plugin = this.plugins[specMessage.home]
        if (plugin) {
          plugin.handle(specMessage, out, () => out(this.continue()), this.sendAbortMessage(out))
        } else {
          console.log("Message for unknown plugin:", specMessage)
        }
        break
    }
  }

  sendAbortMessage(out) {
    return (reason) => {
      out(this.abort(reason))
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
      case "observation": {
        const observation = specMessage.body
        this.emit('observation', observation)
        if (this.options.endOnFailure && observation.summary === "REJECT") {
          out(this.specStateMessage("FINISH"))
        } else {
          out(this.continue())
        }

        break
      }
    }
  }

  handleSpecEvent(specMessage) {
    switch (specMessage.name) {
      case "state": {
        switch (specMessage.body) {
          case "COMPLETE": {
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

  handleScenarioEvent(specMessage, out) {
    switch (specMessage.name) {
      case "state":
        this.handleStateChange(specMessage.body, out)
        break
      case "step":
        this.handleMessage(specMessage.body.message, out)
        this.startStepTimer(out)
        break
      default:
        console.log("Message for unknown scenario event", specMessage)
    }
  }

  handleStateChange(state, out) {
    switch (state) {
      case "START":
        this.prepareForScenario()
        out(this.continue())
        break
      case "CONFIGURE_COMPLETE":
        out(this.continue())
        break
      case "OBSERVATION_START":
        this.scenarioExerciseComplete()
        out(this.continue())
        break
      case "ABORT":
        this.scenarioExerciseComplete()
        break
    }
  }

  abort(reason) {
    return {
      home: "_scenario",
      name: "abort",
      body: reason
    }
  }

  scenarioExerciseComplete() {
    this.stopStepTimer()
    this.portPlugin.unsubscribe()
  }

  prepareForScenario() {
    this.context.clock.runToFrame()
    clearTimers(this.context.window)
    setTimezoneOffset(this.context.window, new Date().getTimezoneOffset())
    setBaseLocation("http://elm-spec", this.context.window)
  }

  startStepTimer(out) {
    this.stopStepTimer()
    this.stepTimeout = setTimeout(() => {
      out(this.continue())
    }, 0)
  }

  stopStepTimer() {
    if (this.stepTimeout) {
      clearTimeout(this.stepTimeout)
      this.stepTimeout = null
    }
  }

  continue () {
    return this.scenarioStateMessage("CONTINUE")
  }

  specStateMessage (state) {
    return {
      home: "_spec",
      name: "state",
      body: state
    }
  }

  scenarioStateMessage (state) {
    return {
      home: "_scenario",
      name: "state",
      body: state
    }
  }
}