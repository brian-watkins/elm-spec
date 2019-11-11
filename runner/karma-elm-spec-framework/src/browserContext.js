const HtmlPlugin = require('elm-spec-core/src/plugin/htmlPlugin')
const HttpPlugin = require('elm-spec-core/src/plugin/httpPlugin')

module.exports = class BrowserContext {
  constructor(window, clock, tags) {
    this.window = window
    this.clock = clock
    this.tags = tags
  }

  evaluate(evaluator) {
    this.execute((Elm, window) => {
      const appElement = this.prepareForApp(window)
      evaluator(Elm, appElement, null, window)
    })
  }

  execute(callback) {
    callback(this.window.Elm, this.window)
  }

  evaluateProgram(program, callback) {
    this.execute((_, window) => {
      const appElement = this.prepareForApp(window)
      this.window._elm_spec.app = this.initializeApp(program, appElement)
      const plugins = this.generatePlugins(window)
      callback(this.window._elm_spec.app, plugins)
    })
  }

  initializeApp(program, element) {
    return program.init({
      node: element,
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

  prepareForApp(window) {
    const document = window.document
    let mountElement = document.querySelector("elm-spec-app")
    if (!mountElement) {
      mountElement = document.createElement("div")
      mountElement.id = "elm-spec-app"
      document.body.appendChild(mountElement)
    }

    while (mountElement.firstChild) {
      mountElement.removeChild(mountElement.firstChild);
    }

    const wrapper = document.createElement("div")
    wrapper.id = "app"
    mountElement.appendChild(wrapper)

    return wrapper
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