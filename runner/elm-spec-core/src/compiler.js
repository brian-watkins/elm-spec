const compiler = require("node-elm-compiler/dist/index")
const glob = require("glob")

module.exports = class Compiler {
  constructor ({ cwd, specPath, elmPath }) {
    this.cwd = cwd
    this.specPath = specPath
    this.elmPath = elmPath
  }

  compile() {
    const files = glob.sync(this.specPath)

    return compiler.compileToStringSync(files, {
      cwd: this.cwd,
      pathToElm: this.elmPath
    })
  }
}