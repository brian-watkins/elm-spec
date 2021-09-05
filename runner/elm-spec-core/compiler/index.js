const ElmContext = require('../src/elmContext')
const compiler = require("node-elm-compiler")
const glob = require('glob')
const path = require('path')

const LOG_LEVEL = Object.freeze({ ALL: 0, QUIET: 1, SILENT: 2 })

const COMPILER_STATUS = Object.freeze({ READY: 0, NO_FILES: 1, COMPILATION_SUCCEEDED: 2, COMPILATION_FAILED: 3 })

const Compiler = class {
  constructor ({ cwd, specPath, elmPath, logLevel }) {
    this.cwd = cwd || process.cwd()
    this.specPath = specPath
    this.elmPath = elmPath && path.relative(this.cwd, elmPath)
    this.logLevel = logLevel || LOG_LEVEL.ALL
    this.compilerStatus = COMPILER_STATUS.READY
  }

  compile() {
    const files = glob.sync(this.specPath, { cwd: this.cwd, absolute: true })

    let header = ElmContext.storeCompiledFiles({ cwd: this.cwd, specPath: this.specPath, files })

    if (files.length == 0) {
      this.compilerStatus = COMPILER_STATUS.NO_FILES
      return header
    }

    try {
      const compiledElm = compiler.compileToStringSync(files, {
        cwd: this.cwd,
        processOpts: {
          stdio: [
            'ignore',
            this.logLevel >= LOG_LEVEL.QUIET ? 'ignore' : 'inherit',
            this.logLevel >= LOG_LEVEL.SILENT ? 'ignore' : 'inherit'
          ]
        },
        pathToElm: this.elmPath
      })

      this.compilerStatus = COMPILER_STATUS.COMPILATION_SUCCEEDED
      return header + ElmContext.setElmCode(compiledElm)
    } catch (_) {
      this.compilerStatus = COMPILER_STATUS.COMPILATION_FAILED
      return header
    }
  }

  status() {
    return this.compilerStatus
  }
}

Compiler.LOG_LEVEL = LOG_LEVEL
Compiler.STATUS = COMPILER_STATUS

module.exports = Compiler