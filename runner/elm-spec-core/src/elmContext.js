const SinonFakeTimers = require("@sinonjs/fake-timers");
const FakeTimer = require('./fakes/fakeTimer')
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
const path = require('path')

module.exports = class ElmContext {
  static storeCompiledFiles({ cwd, specPath, files }) {
    return `
window._elm_spec.compiler = {
  cwd: "${cwd}",
  specPath: "${specPath}",
  files: [${printFiles(files)}]
};
`
  }

  static setElmCode(code) {
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

  constructor(window) {
    this.window = window
    this.timer = new FakeTimer(SinonFakeTimers.createClock())

    this.registerFakes()
  }

  registerFakes() {
    this.window._elm_spec = {}
    this.window._elm_spec.blobStore = new BlobStore()
    const fakeLocation = new FakeLocation(this.sendToProgram())
    this.window._elm_spec.requestAnimationFrame = this.timer.clock.requestAnimationFrame
    this.window._elm_spec.cancelAnimationFrame = this.timer.clock.cancelAnimationFrame
    this.window._elm_spec.date = fakeDate(this.timer.clock)
    this.window._elm_spec.viewportOffset = { x: 0, y: 0 }
    this.window._elm_spec.windowEventListeners = {}
    this.window._elm_spec.window = fakeWindow(this.window, fakeLocation)
    this.window._elm_spec.documentEventListeners = {}
    this.window._elm_spec.fakeDocument = new FakeDocument(this.window, fakeLocation)
    this.window._elm_spec.history = new FakeHistory(fakeLocation)
    this.window._elm_spec.console = proxiedConsole()
    this.window._elm_spec.timer = this.timer
    this.window._elm_spec.url = new FakeURL(this.window._elm_spec.blobStore)
    this.window._elm_spec.mouseEvent = fakeMouseEvent()
    this.window._elm_spec.fileReader = fileReaderProxy(this.timer)
  }

  evaluate(evaluator) {
    evaluator(this.window.Elm)
  }

  static registerFileLoadingCapability(winwdowDecorator, capability) {
    winwdowDecorator("_elm_spec_load_file", capability)
  }

  canLoadFile() {
    return this.window.hasOwnProperty("_elm_spec_load_file")
  }

  readBytesFromFile(filePath) {
    return this.loadFile({ path: filePath, convertToText: false })
  }

  readTextFromFile(filePath) {
    return this.loadFile({ path: filePath, convertToText: true })
  }

  loadFile(options) {
    if (!this.canLoadFile()) {
      return Promise.reject({
        type: "no-load-file-capability"
      })
    }

    return this.window._elm_spec_load_file(options)
  }

  openFileSelector(inputElement) {
    this.window._elm_spec.fileInput = inputElement
    this.sendToProgram()({home: "_html", name: "file-selector-open", body: null})
  }

  registerApp(app) {
    this.window._elm_spec.app = app
  }

  sendToProgram() {
    return (msg) => {
      this.window._elm_spec.app.ports.elmSpecIn.send(msg)
    }
  }

  fileInputForOpenFileSelector() {
    return this.window._elm_spec.fileInput
  }

  closeFileSelector() {
    this.window._elm_spec.fileInput = null
  }

  specFiles() {
    return this.window._elm_spec.compiler.files
  }

  workDir() {
    return this.window._elm_spec.compiler.cwd
  }

  specPath() {
    return this.window._elm_spec.compiler.specPath
  }

  fullPathToModule(moduleName) {
    const modulePath = path.join(...moduleName) + ".elm"
    return this.specFiles().find(f => f.endsWith(modulePath))
  }

  resizeWindowTo(width, height) {
    this.window._elm_spec.innerWidth = width
    this.window._elm_spec.innerHeight = height
  }

  setBrowserViewport(offset) {
    this.window._elm_spec.viewportOffset = offset
  }

  setWindowVisibility(isVisible) {
    this.window._elm_spec.isVisible = isVisible
  }

  setTimezoneOffset(offset) {
    this.window._elm_spec.date.fakeTimezoneOffset = offset
  }

  setBaseLocation(location) {
    this.window._elm_spec.window.location.setBase(this.window.document, location)
  }

  mapElement(mapper) {
    this.window._elm_spec.fakeDocument.addElementMapper(mapper)
  }

  clearElementMappers() {
    this.window._elm_spec.fakeDocument.clearElementMappers()
  }

  blobStore() {
    return this.window._elm_spec.blobStore
  }

  clearEventListeners() {
    forEachListener(this.window._elm_spec.windowEventListeners, (type, fun) => {
      this.window.removeEventListener(type, fun)
    })
    this.window._elm_spec.windowEventListeners = {}

    forEachListener(this.window._elm_spec.documentEventListeners, (type, fun) => {
      this.window.document.removeEventListener(type, fun)
    })
    this.window._elm_spec.documentEventListeners = {}
  }
}

const forEachListener = (list, handler) => {
  for (key in list) {
    list[key].forEach((fun) => {
      handler(key, fun)
    })
  }
}

const printFiles = (files) => {
  return files.map(f => `"${f}"`).join(", ")
}