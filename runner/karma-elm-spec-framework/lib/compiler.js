const Compiler = require('elm-spec-core/compiler')
const path = require('path')
const fs = require('fs')

const defaultConfig = {
  cwd: path.join(process.cwd(), "specs"),
  specPath: "./**/*Spec.elm",
}

const CompilerFactory = (config) => {

  const elmSpecConfig = config.elmSpec || {}

  const workDir = elmSpecConfig.cwd || defaultConfig.cwd

  const compiler = new Compiler({
    cwd: workDir,
    specPath: elmSpecConfig.specs || defaultConfig.specPath,
    elmPath: elmSpecConfig.pathToElm,
    logLevel: Compiler.LOG_LEVEL.ALL
  })

  const compile = function() {
    const compiledCode = compiler.compile()

    const outputPath = path.resolve(workDir, 'elm-stuff', 'elm-spec.js')
    fs.writeFileSync(outputPath, compiledCode)
    return outputPath
  }

  return {
    compile
  }

}

CompilerFactory.$inject = ['config']

module.exports = {
  CompilerFactory
}