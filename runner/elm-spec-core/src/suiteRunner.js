const EventEmitter = require('events')
const ProgramRunner = require('./programRunner')
const Program = require('./program')

const ELM_SPEC_CORE_VERSION = 2

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

    const error = ProgramRunner.hasElmSpecPorts(app)
    if (error) {
      this.reporter.error(error)
      return null
    }

    return app
  }

  runApp(app, programs) {
    new ProgramRunner(app, this.context, this.options)
      .on("observation", (observation) => {
        this.reporter.record(observation)
      })
      .on("complete", (shouldContinue) => {
        if (shouldContinue) {
          this.runNextSpecProgram(programs)
        } else {
          this.finish()
        }
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