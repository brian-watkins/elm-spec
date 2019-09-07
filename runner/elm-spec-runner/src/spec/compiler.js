const compiler = require("node-elm-compiler/dist/index")
const glob = require("glob")

module.exports = class Compiler {
  constructor ({ specPath, elmPath }) {
    this.specPath = specPath
    this.elmPath = elmPath
  }

  compile() {
    return new Promise((resolve, reject) => {
      glob(this.specPath, (err, files) => {
        if (err) reject(err)
        
        compiler.compileToString(files, {
          pathToElm: this.elmPath
        })
        .then((data) => {
          resolve(data.toString())
        })
        .catch((compileError) => {
          reject(compileError)
        })
      })  
    })
  }
}