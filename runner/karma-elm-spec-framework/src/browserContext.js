const lolex = require('lolex')
const { registerFakes } = require('elm-spec-core/src/fakes')

module.exports = class BrowserContext {
  constructor(window, tags) {
    this.window = window
    this.clock = lolex.createClock()
    this.tags = tags

    registerFakes(this.window, this.clock)
  }

  evaluate(evaluator) {
    this.execute((Elm, window) => {
      evaluator(Elm, window)
    })
  }

  execute(callback) {
    callback(this.window.Elm, this.window)
  }

  evaluateProgram(program, callback) {
    this.clock.reset()
    const app = this.initializeApp(program)
    callback(app)
  }

  initializeApp(program) {
    return program.init({
      flags: {
        tags: this.tags
      }
    })
  }

  update(callback) {
    this.clock.runToFrame()
    callback()
  }

}