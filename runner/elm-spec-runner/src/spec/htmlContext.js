const HtmlPlugin = require('elm-spec-core/src/htmlPlugin')
const { JSDOM } = require("jsdom");
const lolex = require('lolex')
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

    this.addFakeWindow()

    this.clock = lolex
      .withGlobal(this.dom.window)
      .install({toFake: [ "requestAnimationFrame" ]})
  }

  addFakeWindow() {
    this.addJs(__dirname + '/fakeWindow.js')
    this.dom.window._elm_spec = {}
    this.dom.window.eval("_elm_spec.window = new FakeWindow()")
  }

  addJs(file) {
    const source = fs.readFileSync(file, { encoding: "utf-8" })
    const script = this.dom.window.document.createElement("script")
    script.textContent = source
    this.dom.window.document.body.appendChild(script)
  }

  evaluateProgram(program, callback) {
    this.execute((_, window) => {
      const appElement = this.prepareForApp(window)
      const app = this.initializeApp(program, appElement)
      const plugins = this.generatePlugins(window, this.clock)
      callback(app, plugins)
    })
  }

  evaluate(evaluator) {
    this.execute((Elm, window) => {
      const appElement = this.prepareForApp(window)
      evaluator(Elm, appElement, this.clock, window)
    })
  }

  execute(callback) {
    if (!this.dom.window.Elm) {
      this.compiler.compile()
        .then((compiledCode) => {
          this.dom.window.eval("(function(){const window = _elm_spec.window; " + compiledCode + "})()")
          callback(this.dom.window.Elm, this.dom.window)
        })
        .catch((err) => {
          console.log(err)
          process.exit(1)
        })
    }
    else {
      callback(this.dom.window.Elm, this.dom.window)
    }
  }

  initializeApp(program, element) {
    return program.init({
      node: element
    })
  }

  generatePlugins(window, clock) {
    return {
      "_html": new HtmlPlugin(window, clock)
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
}
