const EventEmitter = require('events')
const PortPlugin = require('./plugin/portPlugin')
const TimePlugin = require('./plugin/timePlugin')
const HtmlPlugin = require('./plugin/htmlPlugin')
const HttpPlugin = require('./plugin/httpPlugin')
const FilePlugin = require('./plugin/filePlugin')
const WitnessPlugin = require('./plugin/witnessPlugin')
const {
  registerApp,
  setBaseLocation,
  whenStackIsComplete,
  stopWaitingForStack,
  clearEventListeners,
  setTimezoneOffset,
  setBrowserViewport,
  closeFileSelector,
  clearElementMappers,
  getTimer
} = require('./fakes')
const { report, line } = require('./report')

const ELM_SPEC_OUT = "elmSpecOut"
const ELM_SPEC_IN = "elmSpecIn"
const ELM_SPEC_PICK = "elmSpecPick"

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
    this.timer = getTimer(this.context.window)
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
      "_port": this.portPlugin,
      "_file": new FilePlugin(context)
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
      this.startSuite()
    }, 0)
  }

  startSuite() {
    const tags = this.app.ports[ELM_SPEC_PICK] ? [ "_elm_spec_pick" ] : this.options.tags
    this.app.ports[ELM_SPEC_IN].send(this.specStateMessage("start", { tags }))
  }

  handleMessage(specMessage, out) {
    switch (specMessage.home) {
      case "_spec":
        this.handleSpecEvent(specMessage)
        break
      case "_scenario":
        this.handleScenarioEvent(specMessage, out)
        break
      case "_step":
        this.handleStepEvent(specMessage, out)
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
        this.handleMessage(specMessage.body, (message) => {
          out({
            home: "_observer",
            name: "inquiryResult",
            body: message
          })
        })
        break
      case "observation": {
        const observation = specMessage.body
        this.emit('observation', observation)
        if (this.options.endOnFailure && observation.summary === "REJECT") {
          out(this.specStateMessage("finish"))
        } else {
          out(this.continue())
        }

        break
      }
    }
  }

  handleStepEvent(specMessage, out) {
    switch (specMessage.name) {
      case "request":
        this.handleMessage(specMessage.body, (message) => {
          out({
            home: "_step",
            name: "response",
            body: message
          })
        })
        break
      case "program-command":
        whenStackIsComplete(this.context.window, () => {
          if (!this.runAnyExtraAnimationFrameTasks()) {
            out(this.continue())
          }
        })
        break
      case "complete":
        whenStackIsComplete(this.context.window, () => {
          out(this.continue())
        })
        break
      case "log":
        this.emit('log', specMessage.body)
        break
    }
  }

  runAnyExtraAnimationFrameTasks() {
    const currentAnimationFrameTasks = this.timer.currentAnimationFrameTasks()
    const extraAnimationFrameTasks = currentAnimationFrameTasks.length - this.stepAnimationFrameTaskCount
    if (extraAnimationFrameTasks > 0) {
      currentAnimationFrameTasks
        .map(v => v.id)
        .sort((a, b) => a - b)
        .slice(-extraAnimationFrameTasks)
        .forEach(id => {
          this.timer.triggerAnimationFrameTask(String(id))
        })
      return true
    }

    return false
  }

  handleSpecEvent(specMessage) {
    switch (specMessage.name) {
      case "state": {
        switch (specMessage.body) {
          case "COMPLETE": {
            clearElementMappers(this.context.window)
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
        whenStackIsComplete(this.context.window, () => {
          this.configureComplete(out)
        })
        break
      case "step":
        this.stepAnimationFrameTaskCount = this.timer.currentAnimationFrameTasks().length
        this.handleMessage(specMessage.body.message, out)
        whenStackIsComplete(this.context.window, () => {
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
    this.timer.runAllAnimationFrameTasks()
    this.timer.clear()
    clearEventListeners(this.context.window)
    setTimezoneOffset(this.context.window, new Date().getTimezoneOffset())
    setBaseLocation("http://elm-spec", this.context.window)
    setBrowserViewport(this.context.window, { x: 0, y: 0 })
    this.httpPlugin.reset()
    closeFileSelector(this.context.window)
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
    stopWaitingForStack(this.context.window)
    this.portPlugin.unsubscribe()
  }

  continue () {
    return this.scenarioStateMessage("CONTINUE")
  }

  specStateMessage (state, message = null) {
    return {
      home: "_spec",
      name: state,
      body: message
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