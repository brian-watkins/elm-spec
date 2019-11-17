const { JSDOM } = require("jsdom");
const lolex = require('lolex')
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
      this.clock.reset()
      const app = this.initializeApp(program)
      callback(app)
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

  update(callback) {
    this.clock.runToFrame()
    callback()
  }

}
