const { JSDOM } = require("jsdom");

module.exports = class JsdomContext {
  constructor() {
    this.dom = new JSDOM(
      "<html><head><base href='http://elm-spec'></head><body></body></html>",
      { pretendToBeVisual: true,
        runScripts: "dangerously",
        url: "http://elm-spec"
      }
    )
  }

  loadElm(compiler) {
    try {
      const compiledCode = compiler.compile()
      this.dom.window.eval(compiledCode)
    } catch (error) {
      console.log(error)
      process.exit(1)
    }
  }

  get window () {
    return this.dom.window
  }
}
