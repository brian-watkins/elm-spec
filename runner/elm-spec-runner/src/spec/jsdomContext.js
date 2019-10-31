const HtmlPlugin = require('elm-spec-core/src/htmlPlugin')
const HttpPlugin = require('elm-spec-core/src/httpPlugin')
const { JSDOM } = require("jsdom");
const lolex = require('lolex')
const FakeLocation = require('../fakes/fakeLocation')
const FakeHistory = require('../fakes/fakeHistory')
const { proxiedConsole } = require('../fakes/proxiedConsole')
const { fakeWindow } = require('../fakes/fakeWindow')
const { fakeDocument } = require('../fakes/fakeDocument')


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
    this.dom.window._elm_spec.window = fakeWindow(this.dom.window, fakeLocation)
    this.dom.window._elm_spec.document = fakeDocument(this.dom.window, fakeLocation)
    this.dom.window._elm_spec.history = new FakeHistory(fakeLocation)
    this.dom.window._elm_spec.console = proxiedConsole()
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
          this.dom.window.eval("(function(){const console = _elm_spec.console; const window = _elm_spec.window; const history = _elm_spec.history; const document = _elm_spec.document; " + compiledCode + "})()")
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
      "_html": new HtmlPlugin(this, window, clock),
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

  // plugin functions

  get location() {
    return this.dom.window._elm_spec.window.location
  }

  setBaseLocation(location) {
    this.dom.window._elm_spec.window.location.setBase(this.dom.window.document, location)
  }

  resizeTo(width, height) {
    this.dom.window._elm_spec.innerWidth = width
    this.dom.window._elm_spec.innerHeight = height
  }

  setVisibility(isVisible) {
    this.dom.window._elm_spec.isVisible = isVisible
  }
}
