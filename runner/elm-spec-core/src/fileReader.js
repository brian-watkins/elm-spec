const fs = require('fs')
const path = require('path')


module.exports = class FileReader {
  constructor(rootDir) {
    this.rootDir = rootDir
  }

  readFile(file) {
    return new Promise((resolve, reject) => {
      const absPath = path.resolve(this.rootDir, file)
      fs.readFile(absPath, (err, data) => {
        if (err) {
          reject({ type: "file", path: absPath })
        } else {
          resolve({ path: absPath, buffer: data.toJSON() });
        }
      })
    })
  }
}