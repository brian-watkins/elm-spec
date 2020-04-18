const ElmContext = require('./elmContext')
const compiler = require("node-elm-compiler/dist/index")
const glob = require('glob')


module.exports = class Compiler {
  constructor ({ cwd, specPath, elmPath, silent }) {
    this.cwd = cwd || process.cwd()
    this.specPath = specPath
    this.elmPath = elmPath
    this.silent = silent
  }

  compile() {
    const files = glob.sync(this.specPath, { cwd: this.cwd, absolute: true })

    let code = ElmContext.storeCompiledFiles({ cwd: this.cwd, specPath: this.specPath, files })

    if (files.length > 0) {
      const compiledElm = compiler.compileToStringSync(files, {
        cwd: this.cwd,
        processOpts: { stdio: this.silent ? 'ignore' : 'inherit' },
        pathToElm: this.elmPath
      })

      if (compiledElm.length > 0) {
        code += ElmContext.setElmCode(compiledElm)
      }  
    }

    return code
  }
}