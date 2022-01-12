const EventEmitter = require('events')
const SpecRunner = require('./specRunner')
const ProgramReference = require('./programReference')
const { report, line } = require('./report')

const RESULT_STATUS = Object.freeze({ OK: "Ok", ERROR: "Error" })

class SuiteRunner extends EventEmitter {
  constructor(context, reporter, options, version) {
    super()
    this.context = context
    this.reporter = reporter
    this.options = options
    this.version = version || SpecRunner.version()
    this.segment = { id: 0, count: 1 }
  }

  runSegment(id, count) {
    this.segment = { id, count }
    this.runAll()
  }

  runAll() {
    if (this.context.specFiles().length == 0) {
      this.reporter.error(this.noSpecModulesError())
      this.finish(this.errorResult())
      return
    }

    this.context.evaluate((Elm) => {
      if (!Elm) {
        this.reporter.error(this.compilationError())
        this.finish(this.errorResult())
        return
      }

      this.run(ProgramReference.findAll(Elm))
    })
  }

  run(programReferences) {
    this.reporter.startSuite()
    this.summary = { accepted: 0, rejected: 0, skipped: 0 }
    this.runNextSpecProgram(programReferences)
  }

  runNextSpecProgram(programReferences) {
    const programReference = programReferences.shift()
  
    if (programReference === undefined) {
      this.finish(this.okResult())
      return
    }
  
    this.prepareForApp()
    const app = this.initializeApp(programReference.program)

    if (!app) {
      this.finish(this.errorResult())
      return
    }

    const modulePath = this.context.fullPathToModule(programReference.moduleName)
    
    this.runApp(app, modulePath, () => {
      this.runNextSpecProgram(programReferences)
    })
  }

  prepareForApp() {
    this.context.timer.reset()
  }

  initializeApp(program) {
    let app
    
    try {
      app = program.init({
        flags: {
          version: this.version,
          segment: this.segment.id,
          segmentCount: this.segment.count
        }
      })
    } catch (err) {
      this.reporter.error(this.initializationError())
      return null
    }

    const error = SpecRunner.hasElmSpecPorts(app)
    if (error) {
      this.reporter.error(error)
      return null
    }

    return app
  }

  runApp(app, modulePath, runNextSpec) {
    new SpecRunner(app, this.context, this.options)
      .on("observation", (obs) => {
        const observation = Object.assign({ modulePath }, obs)
        this.updateSummary(observation)
        this.reporter.record(observation)
      })
      .on("complete", (shouldContinue) => {
        if (shouldContinue) {
          runNextSpec()
        } else {
          this.finish(this.okResult())
        }
      })
      .on("error", (error) => {
        this.reporter.error(error)
        this.finish(this.errorResult())
      })
      .on("log", (report) => {
        this.reporter.log(report)
      })
      .run()
  }

  updateSummary(observation) {
    switch(observation.summary) {
      case "ACCEPTED":
        this.summary.accepted += 1
        break
      case "REJECTED":
        this.summary.rejected += 1
        break
      case "SKIPPED":
        this.summary.skipped += 1
        break
    }
  }

  finish(result) {
    this.reporter.finish()
    this.emit('complete', result)
  }

  noSpecModulesError() {
    return report(
      line("No spec modules found!"),
      line("Working directory (with elm.json)", this.context.workDir()),
      line("Spec Path (relative to working directory)", this.context.specPath())
    )
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

  okResult() {
    return Object.assign({ status: RESULT_STATUS.OK }, this.summary)
  }

  errorResult() {
    return { status: RESULT_STATUS.ERROR }
  }
}

SuiteRunner.STATUS = RESULT_STATUS

module.exports = SuiteRunner