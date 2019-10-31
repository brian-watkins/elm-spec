const EventEmitter = require('events')
const ProgramRunner = require('./programRunner')
const Program = require('./program')

module.exports = class SuiteRunner extends EventEmitter {
  constructor(context, reporter, options) {
    super()
    this.context = context
    this.reporter = reporter
    this.options = options
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
      new ProgramRunner(app, this.context, plugins, this.options)
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