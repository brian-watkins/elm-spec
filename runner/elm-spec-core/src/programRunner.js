const EventEmitter = require('events')
const PortPlugin = require('./plugin/portPlugin')
const TimePlugin = require('./plugin/timePlugin')
const HtmlPlugin = require('./plugin/htmlPlugin')
const HttpPlugin = require('./plugin/httpPlugin')
const FilePlugin = require('./plugin/filePlugin')
const WitnessPlugin = require('./plugin/witnessPlugin')
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
    this.timer = this.context.timer
    this.plugins = this.generatePlugins(this.context)

    this.portPlugin = new PortPlugin(app)
    this.plugins["_port"] = this.portPlugin

    this.httpPlugin = new HttpPlugin(this.context)
    this.plugins["_http"] = this.httpPlugin

    this.options = options

    this.runAnimationFrame = true
    this.warnOnExtraAnimationFrames = true

    this.context.registerApp(this.app)
  }

  generatePlugins(context) {
    return {
      "_html": new HtmlPlugin(context),
      "_time": new TimePlugin(context),
      "_witness": new WitnessPlugin(),
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
    const tags = this.app.ports[ELM_SPEC_PICK] ? [ "_elm_spec_pick" ] : []
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
      case "_harness":
        this.handleHarnessEvent(specMessage, out)
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

  handleHarnessEvent(specMessage, out) {
    switch (specMessage.name) {
      case "complete":
        this.emit("complete", true)
        break
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
        if (this.options.endOnFailure && observation.summary === "REJECTED") {
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
        this.timer.whenStackIsComplete(() => {
          this.continueToNextStep(out)
        })
        break
      case "complete":
        this.timer.whenStackIsComplete(() => {
          this.continueToNextStep(out)
        })
        break
      case "nextAnimationFrame":
        this.runAnimationFrame = false
        this.timer.runAllAnimationFrameTasks()
        break
      case "log":
        this.emit('log', specMessage.body)
        break
    }
  }

  continueToNextStep(out) {
    if (this.timer.holds > 0) {
      this.timer.whenStackIsComplete(() => {
        this.continueToNextStep(out)
      })
    } else {
      if (this.runAnimationFrame) {
        const tasksBeforeRun = this.timer.animationFrameTaskCount()
        this.timer.runAllAnimationFrameTasks()
        const tasksAfterRun = this.timer.animationFrameTaskCount()

        if (this.shouldReceiveProgramCommand(tasksBeforeRun, tasksAfterRun)) {
          return
        }

        if (this.warnOnExtraAnimationFrames && this.hasExtraRecurringAnimationFrameTasks(tasksAfterRun)) {
          this.abortDueToExtraAnimationFrameTasks(out)
        }
      }

      this.runAnimationFrame = true
      this.timer.stopWaitingForStack()
      out(this.continue())
    }
  }

  shouldReceiveProgramCommand(tasksBeforeRun, tasksAfterRun) {
    return tasksAfterRun > 0 && tasksBeforeRun - tasksAfterRun > 0
  }

  hasExtraRecurringAnimationFrameTasks(tasksAfterRun) {
    return tasksAfterRun > 1
  }

  abortDueToExtraAnimationFrameTasks(out) {
    out(this.abort(report(
      line("A spec step results in extra animation frame tasks!"),
      line("See the documentation for Spec.Time.nextAnimationFrame for more details."),
      line("Set up this scenario with Spec.Time.allowExtraAnimationFrames to ignore this warning.")
    )))
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

  handleScenarioEvent(specMessage, out) {
    switch (specMessage.name) {
      case "state":
        this.handleStateChange(specMessage.body, out)
        break
      case "configure":
        this.handleMessage(specMessage.body.message, out)
        this.timer.whenStackIsComplete(() => {
          this.configureComplete(out)
        })
        break
      case "step":
        this.handleMessage(specMessage.body.message, out)
        this.timer.whenStackIsComplete(() => {
          out(this.continue())
        })
        break
      case "warn-on-extra-animation-frames":
        this.warnOnExtraAnimationFrames = specMessage.body
        break
      default:
        console.log("Message for unknown scenario event", specMessage)
    }
  }

  handleStateChange(state, out) {
    switch (state) {
      case "START":
        this.prepareForScenario()
        if (this.timer.animationFrameTaskCount() > 1) {
          out({
            home: "start",
            name: "flush-animation-tasks",
            body: null
          })
        } else {
          out(this.continue())
        }
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
    this.timer.clearTimers()
    this.context.clearEventListeners()
    this.context.setTimezoneOffset(new Date().getTimezoneOffset())
    this.context.setBaseLocation("http://elm-spec")
    this.context.resizeWindowTo(1280, 800)
    this.context.setBrowserViewport({ x: 0, y: 0 })
    this.httpPlugin.reset()
    this.context.closeFileSelector()
    this.runAnimationFrame = true
    this.warnOnExtraAnimationFrames = true
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
    this.timer.stopWaitingForStack()
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