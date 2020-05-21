const FakeLocation = require('./fakes/fakeLocation')
const FakeHistory = require('./fakes/fakeHistory')
const FakeURL = require('./fakes/fakeURL')
const BlobStore = require('./fakes/blobStore')
const FakeDocument = require('./fakes/fakeDocument')
const { fakeDate } = require('./fakes/fakeDate')
const { proxiedConsole } = require('./fakes/proxiedConsole')
const { fakeWindow } = require('./fakes/fakeWindow')
const { fakeMouseEvent } = require('./fakes/fakeMouseEvent')
const { fileReaderProxy } = require('./fakes/fileReaderProxy')

exports.registerFakes = (window, timer) => {
  window._elm_spec = {}
  window._elm_spec.blobStore = new BlobStore()
  const fakeLocation = new FakeLocation(exports.sendToProgram(window))
  window._elm_spec.requestAnimationFrame = timer.clock.requestAnimationFrame
  window._elm_spec.cancelAnimationFrame = timer.clock.cancelAnimationFrame
  window._elm_spec.date = fakeDate(timer.clock)
  window._elm_spec.viewportOffset = { x: 0, y: 0 }
  window._elm_spec.windowEventListeners = {}
  window._elm_spec.window = fakeWindow(window, fakeLocation)
  window._elm_spec.documentEventListeners = {}
  window._elm_spec.fakeDocument = new FakeDocument(window, fakeLocation)
  window._elm_spec.history = new FakeHistory(fakeLocation)
  window._elm_spec.console = proxiedConsole()
  window._elm_spec.timer = timer
  window._elm_spec.url = new FakeURL(window._elm_spec.blobStore)
  window._elm_spec.mouseEvent = fakeMouseEvent()
  window._elm_spec.fileReader = fileReaderProxy(timer)
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
  const document = theWindow._elm_spec.fakeDocument.proxy;
  const setTimeout = theWindow._elm_spec.timer.fakeSetTimeout();
  const setInterval = theWindow._elm_spec.timer.fakeSetInterval();
  const URL = theWindow._elm_spec.url;
  const MouseEvent = theWindow._elm_spec.mouseEvent;
  const FileReader = theWindow._elm_spec.fileReader;
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

exports.setTimezoneOffset = (window, offset) => {
  window._elm_spec.date.fakeTimezoneOffset = offset
}

exports.setBrowserViewport = (window, offset) => {
  window._elm_spec.viewportOffset = offset
}

exports.closeFileSelector = (window) => {
  window._elm_spec.fileInput = null
}

exports.fileInputForOpenFileSelector = (window) => {
  return window._elm_spec.fileInput
}

exports.openFileSelector = (window, inputElement) => {
  window._elm_spec.fileInput = inputElement
  exports.sendToProgram(window)({home: "_html", name: "file-selector-open", body: null})
}

exports.sendToProgram = (window) => (msg) => {
  window._elm_spec.app.ports.elmSpecIn.send(msg)
}

exports.mapElement = (mapper) => {
  window._elm_spec.fakeDocument.addElementMapper(mapper)
}

exports.clearElementMappers = (window) => {
  window._elm_spec.fakeDocument.clearElementMappers()
}

exports.blobStore = () => {
  return window._elm_spec.blobStore
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