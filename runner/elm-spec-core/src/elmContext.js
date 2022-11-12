const SinonFakeTimers = require("@sinonjs/fake-timers");
const FakeTimer = require('./fakes/fakeTimer')
const FakeLocation = require('./fakes/fakeLocation')
const FakeHistory = require('./fakes/fakeHistory')
const FakeURL = require('./fakes/fakeURL')
const BlobStore = require('./fakes/blobStore')
const FakeDocument = require('./fakes/fakeDocument')
const FakeWindow = require('./fakes/fakeWindow')
const { fakeDate } = require('./fakes/fakeDate')
const { proxiedConsole } = require('./fakes/proxiedConsole')
const { fakeMouseEvent } = require('./fakes/fakeMouseEvent')
const { fileReaderProxy } = require('./fakes/fileReaderProxy');
const FakeBrowser = require("./fakes/fakeBrowser");

module.exports = class ElmContext {
  static storeCompiledFiles(compilerData) {
    return `
window._elm_spec_compiler = ${JSON.stringify(compilerData)};
`
  }

  static setElmCode(code) {
    return `
window._elm_spec_load_elm = (context) => {
  const requestAnimationFrame = context.fakes.requestAnimationFrame;
  const cancelAnimationFrame = context.fakes.cancelAnimationFrame;
  const Date = context.fakes.date;
  const console = context.fakes.console;
  const window = context.fakes.window.proxy;
  const history = context.fakes.history;
  const document = context.fakes.document.proxy;
  const setTimeout = context.fakes.timer.fakeSetTimeout();
  const setInterval = context.fakes.timer.fakeSetInterval();
  const URL = context.fakes.url;
  const MouseEvent = context.fakes.mouseEvent;
  const FileReader = context.fakes.fileReader;
  ${code}
}
`
  }

  constructor(window) {
    this.window = window
    this.timer = new FakeTimer(SinonFakeTimers.createClock())

    this.registerFakes()
  }

  registerFakes() {
    this.fakes = {}
    this.fakes.blobStore = new BlobStore()
    const fakeLocation = new FakeLocation((msg) => { this.sendToProgram(msg) })
    this.fakes.requestAnimationFrame = this.timer.clock.requestAnimationFrame
    this.fakes.cancelAnimationFrame = this.timer.clock.cancelAnimationFrame
    this.fakes.date = fakeDate(this.timer.clock)
    this.fakes.browser = new FakeBrowser()
    this.fakes.windowEventListeners = {}
    this.fakes.window = new FakeWindow(this.window, this.fakes.browser, fakeLocation)
    this.fakes.documentEventListeners = {}
    this.fakes.document = new FakeDocument(this.window, this.fakes.browser, fakeLocation)
    this.fakes.history = new FakeHistory(fakeLocation)
    this.fakes.console = proxiedConsole((message) => { this.logMessage(message) })
    this.fakes.timer = this.timer
    this.fakes.url = new FakeURL(this.fakes.blobStore)
    this.fakes.mouseEvent = fakeMouseEvent()
    this.fakes.fileReader = fileReaderProxy(this.timer)
  }

  evaluate(evaluator) {
    if (typeof Elm === 'undefined' && this.window._elm_spec_load_elm) {
      this.window._elm_spec_load_elm(this)
    }

    return evaluator(this.window.Elm)
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
    this.fileInput = inputElement
    this.sendToProgram({home: "_html", name: "file-selector-open", body: null})
  }

  registerApp(app) {
    this.app = app
  }

  sendToProgram(msg) {
    this.app.ports.elmSpecIn.send(msg)
  }

  registerLogger(logger) {
    this.log = logger
  }

  logMessage(message) {
    this.log(message)
  }

  fileInputForOpenFileSelector() {
    return this.fileInput
  }

  closeFileSelector() {
    this.fileInput = null
  }

  specFiles() {
    return this.window._elm_spec_compiler.files
  }

  workDir() {
    return this.window._elm_spec_compiler.cwd
  }

  specPath() {
    return this.window._elm_spec_compiler.specPath
  }

  fullPathToModule(moduleName) {
    const modulePath = moduleName.join("[/\\\\]") + "\\.elm$"
    return this.specFiles().find(f => f.match(modulePath))
  }

  resizeWindowTo(width, height) {
    this.fakes.browser.innerWidth = width
    this.fakes.browser.innerHeight = height
  }

  setBrowserViewport(offset) {
    this.fakes.browser.viewportOffset = offset
  }

  setWindowVisibility(isVisible) {
    this.fakes.browser.isVisible = isVisible
  }

  setTimezoneOffset(offset) {
    this.fakes.date.fakeTimezoneOffset = offset
  }

  setBaseLocation(location) {
    this.fakes.window.location.setBase(this.window.document, location)
  }

  mapElement(mapper) {
    this.fakes.document.addElementMapper(mapper)
  }

  clearElementMappers() {
    this.fakes.document.clearElementMappers()
  }

  blobStore() {
    return this.fakes.blobStore
  }

  clearEventListeners() {
    forEachListener(this.fakes.window.eventListeners, (type, fun) => {
      this.window.removeEventListener(type, fun)
    })
    this.fakes.window.clearEventListeners()

    forEachListener(this.fakes.document.eventListeners, (type, fun) => {
      this.window.document.removeEventListener(type, fun)
    })
    this.fakes.document.clearEventListeners()
  }
}

const forEachListener = (list, handler) => {
  for (const key in list) {
    list[key].forEach((fun) => {
      handler(key, fun)
    })
  }
}