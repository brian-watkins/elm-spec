const { JSDOM } = require("jsdom");
const fs = require('fs')

module.exports = class HtmlContext {
  constructor(compiler) {
    this.compiler = compiler
    this.dom = new JSDOM(
      "<html><head></head><body></body></html>",
      { pretendToBeVisual: true,
        runScripts: "dangerously"
      }
    )
  }

  evaluate(evaluator) {
    if (!this.dom.window.Elm) {
      this.compiler.compile()
        .then((compiledCode) => {
          this.addJs("../node_modules/lolex/lolex.js", this.dom.window)
          this.clock = this.dom.window.eval('lolex.install({toFake: [ "requestAnimationFrame" ]})')
          this.dom.window.eval(compiledCode)
          const appElement = this.prepareForApp(this.dom.window)
          evaluator(this.dom.window.Elm, appElement, this.clock, this.dom.window.document)
        })
        .catch((err) => {
          console.log(err)
          process.exit(1)
        })
    }
    else {
      const appElement = this.prepareForApp(this.dom.window)
      evaluator(this.dom.window.Elm, appElement, this.clock, this.dom.window.document)
    }
  }

  prepareForApp(window) {
    this.clock.reset()

    const document = window.document

    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }

    const wrapper = document.createElement("div")
    wrapper.id = "app"
    document.body.appendChild(wrapper)

    return wrapper
  }

  addJs(file, window) {
    const source = fs.readFileSync(file, { encoding: "utf-8" })
    const script = window.document.createElement("script")
    script.textContent = source
    window.document.body.appendChild(script)
  }
}
