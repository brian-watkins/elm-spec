const EventEmitter = require('events')
const ProgramRunner = require('./programRunner')
const ProgramReference = require('./programReference')
const { report, line } = require('./report')

const ELM_SPEC_CORE_VERSION = 5

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
        this.reporter.error(this.compilationError())
        this.finish()
        return
      }

      this.run(ProgramReference.findAll(Elm))
    })
  }

  run(programReferences) {
    this.reporter.startSuite()
    this.runNextSpecProgram(programReferences)
  }

  runNextSpecProgram(programReferences) {
    const programReference = programReferences.shift()
  
    if (programReference === undefined) {
      this.finish()
      return
    }
  
    this.prepareForApp()
    const app = this.initializeApp(programReference.program)

    if (!app) {
      this.finish()
      return
    }

    this.runApp(app, programReference.path, () => {
      this.runNextSpecProgram(programReferences)
    })
  }

  prepareForApp() {
    this.context.clock.reset()
  }

  initializeApp(program) {
    let app
    
    try {
      app = program.init({
        flags: {
          version: this.version
        }
      })
    } catch (err) {
      this.reporter.error(this.initializationError())
      return null
    }

    const error = ProgramRunner.hasElmSpecPorts(app)
    if (error) {
      this.reporter.error(error)
      return null
    }

    return app
  }

  runApp(app, modulePath, runNextSpec) {
    new ProgramRunner(app, this.context, this.options)
      .on("observation", (obs) => {
        const observation = Object.assign(obs, { modulePath })
        this.reporter.record(observation)
      })
      .on("complete", (shouldContinue) => {
        if (shouldContinue) {
          runNextSpec()
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

  compilationError() {
    return report(
      line("Unable to compile the elm-spec program!")
    )
  }

  initializationError() {
    return report(
      line("Unable to initialize the spec program!"),
      line("This suggests that your elm-spec Elm package expects a different version of elm-spec-core."),
      line("Try upgrading your JavaScript runner and/or your elm-spec Elm package to the latest version.")
    )
  }
}