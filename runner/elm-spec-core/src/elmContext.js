const lolex = require('lolex')
const { registerFakes } = require('./fakes')

module.exports = class ElmContext {
  constructor(window) {
    this.window = window
    this.clock = lolex.createClock()

    registerFakes(this.window, this.clock)
  }

  evaluate(evaluator) {
    evaluator(this.window.Elm)
  }
}