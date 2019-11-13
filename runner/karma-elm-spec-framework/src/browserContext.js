const lolex = require('lolex')
const HtmlPlugin = require('elm-spec-core/src/plugin/htmlPlugin')
const HttpPlugin = require('elm-spec-core/src/plugin/httpPlugin')
const FakeLocation = require('elm-spec-core/src/fakes/fakeLocation')
const FakeHistory = require('elm-spec-core/src/fakes/fakeHistory')
const { proxiedConsole } = require('elm-spec-core/src/fakes/proxiedConsole')
const { fakeWindow } = require('elm-spec-core/src/fakes/fakeWindow')
const { fakeDocument } = require('elm-spec-core/src/fakes/fakeDocument')

module.exports = class BrowserContext {
  constructor(window, tags) {
    this.window = window
    this.clock = lolex.createClock()
    this.tags = tags

    this.addFakes()
  }

  addFakes() {
    this.window._elm_spec = {}
    const fakeLocation = new FakeLocation((msg) => console.log("send to program", msg))
    this.window._elm_spec.window = fakeWindow(this.window, fakeLocation, this.clock)
    this.window._elm_spec.document = fakeDocument(this.window, fakeLocation)
    this.window._elm_spec.history = new FakeHistory(fakeLocation)
    this.window._elm_spec.console = proxiedConsole()
  }

  evaluate(evaluator) {
    this.execute((Elm, window) => {
      evaluator(Elm, window)
    })
  }

  execute(callback) {
    callback(this.window.Elm, this.window)
  }

  evaluateProgram(program, callback) {
    this.execute((_, window) => {
      this.window._elm_spec.app = this.initializeApp(program)
      const plugins = this.generatePlugins(window)
      callback(this.window._elm_spec.app, plugins)
    })
  }

  initializeApp(program) {
    return program.init({
      flags: {
        tags: this.tags
      }
    })
  }

  generatePlugins(window) {
    return {
      "_html": new HtmlPlugin(this, window),
      "_http": new HttpPlugin(window)
    }
  }

  prepareForScenario() {
    this.window._elm_spec.window.location.setBase(this.window.document, "http://elm-spec")
  }

  update(callback) {
    this.clock.runToFrame()
    this.window.requestAnimationFrame(callback)
  }

  // plugin functions

  get location() {
    return this.window._elm_spec.window.location
  }

  setBaseLocation(location) {
    this.window._elm_spec.window.location.setBase(this.window.document, location)
  }

  resizeTo(width, height) {
    this.window._elm_spec.innerWidth = width
    this.window._elm_spec.innerHeight = height
  }

  setVisibility(isVisible) {
    this.window._elm_spec.isVisible = isVisible
  }
}