const { JSDOM } = require("jsdom");
const lolex = require('lolex')
const HtmlPlugin = require('elm-spec-core/src/plugin/htmlPlugin')
const HttpPlugin = require('elm-spec-core/src/plugin/httpPlugin')
const { registerFakes } = require('elm-spec-core/src/fakes')


module.exports = class JsdomContext {
  constructor(compiler, tags) {
    this.compiler = compiler
    this.tags = tags

    this.dom = new JSDOM(
      "<html><head><base href='http://elm-spec'></head><body></body></html>",
      { pretendToBeVisual: true,
        runScripts: "dangerously",
        url: "http://elm-spec"
      }
    )

    this.clock = lolex.createClock()

    registerFakes(this.dom.window, this.clock)
  }

  get window () {
    return this.dom.window
  }

  evaluateProgram(program, callback) {
    this.execute((_, window) => {
      const app = this.initializeApp(program)
      const plugins = this.generatePlugins(window)
      callback(app, plugins)
    })
  }

  evaluate(evaluator) {
    this.execute(evaluator)
  }

  execute(callback) {
    if (!this.dom.window.Elm) {
      try {
        const compiledCode = this.compiler.compile()
        this.dom.window.eval(compiledCode)
        callback(this.dom.window.Elm, this.dom.window)
      } catch (error) {
        console.log(error)
        process.exit(1)
      }
    }
    else {
      callback(this.dom.window.Elm, this.dom.window)
    }
  }

  initializeApp(program) {
    return program.init({
      flags: {
        tags: this.tags
      }
    })
  }

  generatePlugins(window, clock) {
    return {
      "_html": new HtmlPlugin(this, window),
      "_http": new HttpPlugin(window)
    }
  }

  update(callback) {
    this.clock.runToFrame()
    callback()
  }

}
