const { JSDOM } = require("jsdom");
const lolex = require('lolex')
const HtmlPlugin = require('elm-spec-core/src/plugin/htmlPlugin')
const HttpPlugin = require('elm-spec-core/src/plugin/httpPlugin')
const FakeLocation = require('elm-spec-core/src/fakes/fakeLocation')
const FakeHistory = require('elm-spec-core/src/fakes/fakeHistory')
const { proxiedConsole } = require('elm-spec-core/src/fakes/proxiedConsole')
const { fakeWindow } = require('elm-spec-core/src/fakes/fakeWindow')
const { fakeDocument } = require('elm-spec-core/src/fakes/fakeDocument')


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

    this.addFakes()
  }

  prepareForScenario() {
    this.dom.window._elm_spec.window.location.setBase(this.dom.window.document, "http://elm-spec")
  }

  addFakes() {
    this.dom.window._elm_spec = {}
    const fakeLocation = new FakeLocation((msg) => this.sendToCurrentApp(msg)) 
    this.dom.window._elm_spec.window = fakeWindow(this.dom.window, fakeLocation, this.clock)
    this.dom.window._elm_spec.document = fakeDocument(this.dom.window, fakeLocation)
    this.dom.window._elm_spec.history = new FakeHistory(fakeLocation)
    this.dom.window._elm_spec.console = proxiedConsole()
  }

  sendToCurrentApp(msg) {
    this.dom.window._elm_spec.app.ports.sendIn.send(msg)
  }

  evaluateProgram(program, callback) {
    this.execute((_, window) => {
      this.dom.window._elm_spec.app = this.initializeApp(program)
      const plugins = this.generatePlugins(window)
      callback(this.dom.window._elm_spec.app, plugins)
    })
  }

  evaluate(evaluator) {
    this.execute(evaluator)
  }

  execute(callback) {
    if (!this.dom.window.Elm) {
      try {
        const compiledCode = this.compiler.compile()
        this.dom.window.eval("(function(){const requestAnimationFrame = _elm_spec.window.requestAnimationFrame; const console = _elm_spec.console; const window = _elm_spec.window; const history = _elm_spec.history; const document = _elm_spec.document; " + compiledCode + "})()")
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
