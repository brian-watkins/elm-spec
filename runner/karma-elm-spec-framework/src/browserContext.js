const lolex = require('lolex')
const { registerFakes } = require('elm-spec-core/src/fakes')

module.exports = class BrowserContext {
  constructor(window) {
    this.window = window
    this.clock = lolex.createClock()

    registerFakes(this.window, this.clock)
  }

  evaluate(evaluator) {
    evaluator(this.window.Elm)
  }
}