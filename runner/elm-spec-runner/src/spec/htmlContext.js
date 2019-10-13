const HtmlPlugin = require('elm-spec-core/src/htmlPlugin')
const HttpPlugin = require('elm-spec-core/src/httpPlugin')
const { JSDOM } = require("jsdom");
const lolex = require('lolex')
const FakeLocation = require('../fakes/fakeLocation')
const FakeHistory = require('../fakes/fakeHistory')

module.exports = class HtmlContext {
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

    this.addFakes()

    this.clock = lolex
      .withGlobal(this.dom.window)
      .install({toFake: [ "requestAnimationFrame" ]})
  }

  prepareForScenario() {
    this.dom.window._elm_spec.window.location.setBase(this.dom.window.document, "http://elm-spec")
  }

  addFakes() {
    this.dom.window._elm_spec = {}
    const fakeLocation = new FakeLocation((msg) => this.sendToCurrentApp(msg)) 
    this.dom.window._elm_spec.window = FakeLocation.forOwner(this.dom.window, fakeLocation)
    this.dom.window._elm_spec.document = FakeLocation.forOwner(this.dom.window.document, fakeLocation)
    this.dom.window._elm_spec.history = new FakeHistory(fakeLocation)
  }

  sendToCurrentApp(msg) {
    this.dom.window._elm_spec.app.ports.sendIn.send(msg)
  }

  evaluateProgram(program, callback) {
    this.execute((_, window) => {
      const appElement = this.prepareForApp(window)
      this.dom.window._elm_spec.app = this.initializeApp(program, appElement)
      const plugins = this.generatePlugins(window, this.clock)
      callback(this.dom.window._elm_spec.app, plugins)
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
          this.dom.window.eval("(function(){const window = _elm_spec.window; const history = _elm_spec.history; const document = _elm_spec.document; " + compiledCode + "})()")
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
      node: element,
      flags: {
        tags: this.tags
      }
    })
  }

  generatePlugins(window, clock) {
    return {
      "_html": new HtmlPlugin(window, clock),
      "_http": new HttpPlugin(window)
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
