const EventEmitter = require('events')
const ProgramRunner = require('./programRunner')
const Program = require('./program')
const { report, line } = require('./report')

const ELM_SPEC_CORE_VERSION = 1

module.exports = class SuiteRunner extends EventEmitter {
  constructor(context, reporter, options, version) {
    super()
    this.context = context
    this.reporter = reporter
    this.options = options
    this.version = version || ELM_SPEC_CORE_VERSION
  }

  runAll() {
    this.context.evaluate((Elm) => {
      if (!Elm) {
        this.finish()
        return
      }

      this.run(Program.discover(Elm))
    })
  }

  run(programs) {
    this.reporter.startSuite()
    this.runNextSpecProgram(programs)
  }

  runNextSpecProgram(programs) {
    const program = programs.shift()
  
    if (program === undefined) {
      this.finish()
      return
    }
  
    this.prepareForApp()
    const app = this.initializeApp(program)

    if (!app) {
      this.finish()
      return
    }

    this.runApp(app, programs)
  }

  prepareForApp() {
    this.context.clock.reset()
  }

  initializeApp(program) {
    const app = program.init({
      flags: {
        tags: this.options.tags,
        version: this.version
      }
    })

    if (!app.ports.hasOwnProperty("sendOut")) {
      this.reporter.error(report(
        line("No sendOut port found!"),
        line("Make sure your elm-spec program uses a port defined like so", "port sendOut : Message -> Cmd msg")
      ))
      return null
    }

    if (!app.ports.hasOwnProperty("sendIn")) {
      this.reporter.error(report(
        line("No sendIn port found!"),
        line("Make sure your elm-spec program uses a port defined like so", "port sendIn : (Message -> msg) -> Sub msg")
      ))
      return null
    }

    return app
  }

  runApp(app, programs) {
    new ProgramRunner(app, this.context, this.options)
      .on("observation", (observation) => {
        this.reporter.record(observation)
      })
      .on("complete", () => {
        this.runNextSpecProgram(programs)
      })
      .on("finished", () => {
        this.finish()
      })
      .on("error", (error) => {
        this.reporter.error(error)
        this.finish()
      })
      .run()
  }

  finish() {
    this.reporter.finish()
    this.emit('complete')
  }
}