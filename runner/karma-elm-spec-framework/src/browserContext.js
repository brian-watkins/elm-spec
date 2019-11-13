const lolex = require('lolex')
const HtmlPlugin = require('elm-spec-core/src/plugin/htmlPlugin')
const HttpPlugin = require('elm-spec-core/src/plugin/httpPlugin')
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
    this.execute((_, window) => {
      const app = this.initializeApp(program)
      const plugins = this.generatePlugins(window)
      callback(app, plugins)
    })
  }

  initializeApp(program) {
    return program.init({
      flags: {
        tags: this.tags
      }
    })
  }

  generatePlugins(window) {
    return {
      "_html": new HtmlPlugin(this, window),
      "_http": new HttpPlugin(window)
    }
  }

  update(callback) {
    this.clock.runToFrame()
    this.window.requestAnimationFrame(callback)
  }

}