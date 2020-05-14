const ElmContext = require('./elmContext')
const compiler = require("node-elm-compiler/dist/index")
const glob = require('glob')
const path = require('path')

const LOG_LEVEL = Object.freeze({ ALL: 0, QUIET: 1, SILENT: 2 })

const Compiler = class {
  constructor ({ cwd, specPath, elmPath, logLevel }) {
    this.cwd = cwd || process.cwd()
    this.specPath = specPath
    this.elmPath = elmPath
    this.logLevel = logLevel || LOG_LEVEL.ALL
  }

  compile() {
    const files = glob.sync(this.specPath, { cwd: this.cwd, absolute: true })

    let code = ElmContext.storeCompiledFiles({ cwd: this.cwd, specPath: this.specPath, files })

    if (files.length > 0) {
      const compiledElm = compiler.compileToStringSync(files, {
        cwd: path.resolve(this.cwd),
        processOpts: {
          stdio: [
            'ignore',
            this.logLevel >= LOG_LEVEL.QUIET ? 'ignore' : 'inherit',
            this.logLevel >= LOG_LEVEL.SILENT ? 'ignore' : 'inherit'
          ] 
        },
        pathToElm: this.elmPath ? path.resolve(this.elmPath) : undefined
      })

      if (compiledElm.length > 0) {
        code += ElmContext.setElmCode(compiledElm)
      }  
    }

    return code
  }
}

Compiler.LOG_LEVEL = LOG_LEVEL

module.exports = Compiler