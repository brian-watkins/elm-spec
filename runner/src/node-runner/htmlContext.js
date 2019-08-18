const { JSDOM } = require("jsdom");

module.exports = class HtmlContext {
  constructor(compiler) {
    this.compiler = compiler
    this.dom = new JSDOM(
      "<html><head></head><body></body></html>",
      { pretendToBeVisual: true
      , runScripts: "outside-only"
      }
    )
  }

  evaluate(evaluator) {
    if (!this.dom.window.Elm) {
      this.compiler.compile()
        .then((compiledCode) => {
          this.dom.window.eval(compiledCode)
          const appElement = this.prepareForApp(this.dom.window)
          evaluator(this.dom.window.Elm, appElement, this.dom.window.document)
        })
        .catch((err) => {
          console.log(err)
          process.exit(1)
        })
    }
    else {
      const appElement = this.prepareForApp(this.dom.window)
      evaluator(this.dom.window.Elm, appElement, this.dom.window.document)
    }
  }

  prepareForApp(window) {
    window.__stopAllTimers()

    const document = window.document

    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }

    const wrapper = document.createElement("div")
    wrapper.id = "app"
    document.body.appendChild(wrapper)

    return wrapper
  }
}
