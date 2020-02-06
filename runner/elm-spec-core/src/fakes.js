const FakeLocation = require('./fakes/fakeLocation')
const FakeHistory = require('./fakes/fakeHistory')
const FakeTimer = require('./fakes/fakeTimer')
const { fakeDate } = require('./fakes/fakeDate')
const { proxiedConsole } = require('./fakes/proxiedConsole')
const { fakeWindow } = require('./fakes/fakeWindow')
const { fakeDocument } = require('./fakes/fakeDocument')

exports.registerFakes = (window, clock) => {
  window._elm_spec = {}
  const fakeLocation = new FakeLocation((msg) => window._elm_spec.app.ports.elmSpecIn.send(msg))
  window._elm_spec.requestAnimationFrame = clock.requestAnimationFrame
  window._elm_spec.cancelAnimationFrame = clock.cancelAnimationFrame
  window._elm_spec.date = fakeDate(clock)
  window._elm_spec.viewportOffset = { x: 0, y: 0 }
  window._elm_spec.windowEventListeners = {}
  window._elm_spec.window = fakeWindow(window, fakeLocation)
  window._elm_spec.documentEventListeners = {}
  window._elm_spec.document = fakeDocument(window, fakeLocation)
  window._elm_spec.history = new FakeHistory(fakeLocation)
  window._elm_spec.console = proxiedConsole()
  window._elm_spec.timer = new FakeTimer(clock)
}

exports.injectFakes = (code) => {
  return `
(function(theWindow){
  const requestAnimationFrame = theWindow._elm_spec.requestAnimationFrame;
  const cancelAnimationFrame = theWindow._elm_spec.cancelAnimationFrame;
  const Date = theWindow._elm_spec.date;
  const console = theWindow._elm_spec.console;
  const window = theWindow._elm_spec.window;
  const history = theWindow._elm_spec.history;
  const document = theWindow._elm_spec.document;
  const setTimeout = theWindow._elm_spec.timer.fakeSetTimeout(theWindow);
  const setInterval = theWindow._elm_spec.timer.fakeSetInterval();
  ${code}
})(window)
`
}

exports.registerApp = (app, window) => {
  window._elm_spec.app = app
}

exports.setBaseLocation = (location, window) => {
  window._elm_spec.window.location.setBase(window.document, location)
}

exports.resizeWindowTo = (width, height, window) => {
  window._elm_spec.innerWidth = width
  window._elm_spec.innerHeight = height
}

exports.setWindowVisibility = (isVisible, window) => {
  window._elm_spec.isVisible = isVisible
}

exports.clearTimers = (window) => {
  window._elm_spec.timer.clear()
}

exports.setTimezoneOffset = (window, offset) => {
  window._elm_spec.date.fakeTimezoneOffset = offset
}

exports.setViewportOffset = (window, offset) => {
  window._elm_spec.viewportOffset = offset
}

exports.clearEventListeners = (window) => {
  forEachListener(window._elm_spec.windowEventListeners, (type, fun) => {
    window.removeEventListener(type, fun)
  })
  window._elm_spec.windowEventListeners = {}

  forEachListener(window._elm_spec.documentEventListeners, (type, fun) => {
    window.document.removeEventListener(type, fun)
  })
  window._elm_spec.documentEventListeners = {}
}

const forEachListener = (list, handler) => {
  for (key in list) {
    list[key].forEach((fun) => {
      handler(key, fun)
    })
  }
}