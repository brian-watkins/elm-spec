const { JSDOM } = require("jsdom");

module.exports = class HtmlContext {
  constructor(compiler) {
    this.compiler = compiler
  }

  evaluate(evaluator) {
    this.dom = new JSDOM(
      "<html><head></head><body><div id='app'></div></body></html>", 
      { runScripts: "outside-only"
      }
    )

    this.compiler.compile()
      .then((compiledCode) => {
        this.dom.window.eval(compiledCode)
        evaluator(this.dom.window.Elm, this.dom.window.document)
      })
      .catch((err) => {
        console.log(err)
        process.exit(1)
      })
  }
}
