const compiler = require("node-elm-compiler/dist/index")
const glob = require("glob")
const { injectFakes } = require('./fakes')

module.exports = class Compiler {
  constructor ({ cwd, specPath, elmPath }) {
    this.cwd = cwd || process.cwd()
    this.specPath = specPath
    this.elmPath = elmPath
  }

  compile() {
    const files = glob.sync(this.specPath, { cwd: this.cwd })

    const compiledElm = compiler.compileToStringSync(files, {
      cwd: this.cwd,
      pathToElm: this.elmPath
    })

    return injectFakes(compiledElm)
  }
}