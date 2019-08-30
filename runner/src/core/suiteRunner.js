const EventEmitter = require('events')
const ProgramRunner = require('./programRunner')
const Program = require('./program')

module.exports = class SuiteRunner extends EventEmitter {
  constructor(context, reporter) {
    super()
    this.context = context
    this.reporter = reporter
  }

  run() {
    this.context.evaluate((Elm) => {
      let programs = Program.discover(Elm)
      this.runNextSpecProgram(programs)
    })
  }

  runNextSpecProgram(programs) {
    const program = programs.shift()
  
    if (program === undefined) {
      this.reporter.finish()
      this.emit('complete')
      return
    }
  
    this.context.evaluateProgram(program, (app, plugins) => {
      new ProgramRunner(app, plugins)
        .on("observation", (observation) => {
          this.reporter.record(observation)
        })
        .on("complete", () => {
          this.runNextSpecProgram(programs)
        })
        .on("error", (error) => {
          this.reporter.error(error)
        })
        .run()  
    })
  }
}