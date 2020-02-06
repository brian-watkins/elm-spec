const EventEmitter = require('events')
const PortPlugin = require('./plugin/portPlugin')
const TimePlugin = require('./plugin/timePlugin')
const HtmlPlugin = require('./plugin/htmlPlugin')
const HttpPlugin = require('./plugin/httpPlugin')
const WitnessPlugin = require('./plugin/witnessPlugin')
const {
  registerApp,
  setBaseLocation,
  clearTimers,
  clearEventListeners,
  setTimezoneOffset,
  setViewportOffset
} = require('./fakes')
const { report, line } = require('./report')

const ELM_SPEC_OUT = "elmSpecOut"
const ELM_SPEC_IN = "elmSpecIn"

module.exports = class ProgramRunner extends EventEmitter {
  static hasElmSpecPorts(app) {
    if (!app.ports.hasOwnProperty(ELM_SPEC_OUT)) {
      return report(
        line(`No ${ELM_SPEC_OUT} port found!`),
        line("Make sure your elm-spec program uses a port defined like so", `port ${ELM_SPEC_OUT} : Message -> Cmd msg`)
      )
    }

    if (!app.ports.hasOwnProperty(ELM_SPEC_IN)) {
      return report(
        line(`No ${ELM_SPEC_IN} port found!`),
        line("Make sure your elm-spec program uses a port defined like so", `port ${ELM_SPEC_IN} : (Message -> msg) -> Sub msg`)
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
    this.httpPlugin = new HttpPlugin(this.context)
    this.plugins = this.generatePlugins(this.context)
    this.options = options

    registerApp(this.app, this.context.window)
  }

  generatePlugins(context) {
    return {
      "_html": new HtmlPlugin(context),
      "_http": this.httpPlugin,
      "_time": new TimePlugin(context),
      "_witness": new WitnessPlugin(),
      "_port": this.portPlugin
    }
  }

  run() {
    const messageHandler = (specMessage) => {
      this.handleMessage(specMessage, (outMessage) => {
        this.app.ports[ELM_SPEC_IN].send(outMessage)
      })
    }

    this.app.ports[ELM_SPEC_OUT].subscribe(messageHandler)
    this.stopHandlingMessages = () => { this.app.ports[ELM_SPEC_OUT].unsubscribe(messageHandler) }

    setTimeout(() => {
      this.app.ports[ELM_SPEC_IN].send(this.specStateMessage("START"))
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
      case "configure":
        this.handleMessage(specMessage.body.message, out)
        this.whenStackIsComplete(() => {
          this.configureComplete(out)
        })
        break
      case "step":
        this.handleMessage(specMessage.body.message, out)
        this.whenStackIsComplete(() => {
          out(this.continue())
        })
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
        this.configureComplete(out)
        break
      case "OBSERVATION_START":
        this.scenarioExerciseComplete()
        out(this.continue())
        break
      case "ABORT":
        this.detachProgram()
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

  prepareForScenario() {
    this.context.clock.runToFrame()
    clearEventListeners(this.context.window)
    clearTimers(this.context.window)
    setTimezoneOffset(this.context.window, new Date().getTimezoneOffset())
    setBaseLocation("http://elm-spec", this.context.window)
    setViewportOffset(this.context.window, { x: 0, y: 0 })
    this.httpPlugin.reset()
  }

  configureComplete(out) {
    this.portPlugin.subscribe({ ignore: [ ELM_SPEC_OUT ]})
    out({
      home: "_configure",
      name: "complete",
      body: null
    })
  }

  scenarioExerciseComplete() {
    this.detachProgram()
  }

  detachProgram() {
    this.stopWaitingForStack()
    this.portPlugin.unsubscribe()
  }

  whenStackIsComplete(andThen) {
    this.stopWaitingForStack()
    this.stackTimeout = setTimeout(andThen, 0)
  }

  stopWaitingForStack() {
    if (this.stackTimeout) {
      clearTimeout(this.stackTimeout)
      this.stackTimeout = null
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