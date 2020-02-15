const compiler = require("node-elm-compiler/dist/index")
const { injectFakes } = require('./fakes')

module.exports = class Compiler {
  constructor ({ cwd, elmPath }) {
    this.cwd = cwd || process.cwd()
    this.elmPath = elmPath
  }

  compileFiles(files) {
    const compiledElm = compiler.compileToStringSync(files, {
      cwd: this.cwd,
      pathToElm: this.elmPath
    })

    return injectFakes(compiledElm)
  }
}