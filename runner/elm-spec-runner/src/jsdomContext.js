const { JSDOM } = require("jsdom");
const lolex = require('lolex')
const { registerFakes } = require('elm-spec-core/src/fakes')


module.exports = class JsdomContext {
  constructor(compiler) {
    this.compiler = compiler

    this.dom = new JSDOM(
      "<html><head><base href='http://elm-spec'></head><body></body></html>",
      { pretendToBeVisual: true,
        runScripts: "dangerously",
        url: "http://elm-spec"
      }
    )

    this.clock = lolex.createClock()

    registerFakes(this.dom.window, this.clock)
    this.generateElm()
  }

  generateElm() {
    try {
      const compiledCode = this.compiler.compile()
      this.dom.window.eval(compiledCode)
    } catch (error) {
      console.log(error)
      process.exit(1)
    }
  }

  get window () {
    return this.dom.window
  }

  evaluate(evaluator) {
    evaluator(this.dom.window.Elm)
  }
}
