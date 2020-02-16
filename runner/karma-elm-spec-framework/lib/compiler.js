const { Compiler } = require('elm-spec-core')
const path = require('path')
const fs = require('fs')

const defaultConfig = {
  cwd: path.join(process.cwd(), "specs"),
  specPath: "./**/*Spec.elm",
}

const CompilerFactory = (config) => {

  const workDir = config.elmSpec.cwd || defaultConfig.cwd

  const compiler = new Compiler({
    cwd: workDir,
    specPath: config.elmSpec.specs || defaultConfig.specPath,
    elmPath: config.elmSpec.pathToElm
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