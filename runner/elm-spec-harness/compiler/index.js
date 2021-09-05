const CoreCompiler = require('elm-spec-core/compiler')

module.exports = class Compiler extends CoreCompiler {
  constructor({ cwd, harnessPath, elmPath, logLevel }) {
    super({ cwd, specPath: harnessPath, elmPath, logLevel })
  }
}