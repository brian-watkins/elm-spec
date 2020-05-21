const SinonFakeTimers = require("@sinonjs/fake-timers");
const FakeTimer = require('./fakes/fakeTimer')
const { registerFakes, injectFakes } = require('./fakes')
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
    return injectFakes(code)
  }

  constructor(window) {
    this.window = window
    this.timer = new FakeTimer(SinonFakeTimers.createClock())

    registerFakes(this.window, this.timer)
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
}

const printFiles = (files) => {
  return files.map(f => `"${f}"`).join(", ")
}