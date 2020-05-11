const FileReader = require('./fileReader')

module.exports = class BrowserContext {
  static canReadFiles(window) {
    return window.hasOwnProperty("_elm_spec_read_file")
  }

  static readFile(window, filePath) {
    return window._elm_spec_read_file(filePath)
  }

  constructor({ rootDir }) {
    this.rootDir = rootDir
  }

  async decorateWindow(decorator) {
    const fileReader = new FileReader(this.rootDir)

    await decorator("_elm_spec_read_file", (filePath) => {
      return fileReader.readFile(filePath)
    })
  }
}