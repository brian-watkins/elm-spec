const fs = require('fs')
const path = require('path')
const { ElmContext } = require('elm-spec-core')


module.exports = class FileLoader {
  constructor(rootDir) {
    this.rootDir = rootDir
  }

  async decorateWindow(decorator) {
    ElmContext.registerFileLoadingCapability(decorator, (options) => {
      return this.handleFileLoad(options)
    })
  }

  handleFileLoad(options) {
    if (options.convertToText) {
      return this.readText(options.path)
    } else {
      return this.readBytes(options.path)
    }
  }

  read(file) {
    return new Promise((resolve, reject) => {
      const absPath = path.resolve(this.rootDir, file)
      fs.readFile(absPath, (err, data) => {
        if (err) {
          reject({ type: "file", path: absPath })
        } else {
          resolve({ path: absPath, buffer: data });
        }
      })
    })
  }

  readBytes(file) {
    return this.read(file)
      .then(({ path, buffer}) => {
        return { path, buffer: buffer.toJSON() }
      })
  }

  readText(file) {
    return this.read(file)
      .then(({ path, buffer }) => {
        return { path, text: buffer.toString() }
      })
  }
}