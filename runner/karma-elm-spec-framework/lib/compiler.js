const { Compiler } = require('elm-spec-core')
const path = require('path')
const fs = require('fs')

const defaultConfig = {
  cwd: process.cwd(),
  elmPath: "elm"
}

const CompilerFactory = (config, specFileProvider) => {

  const compilerOptions = Object.assign(defaultConfig, config.elmSpec)
  const compiler = new Compiler(compilerOptions)

  const compile = function() {
    specFileProvider.findFiles()
    const compiledCode = compiler.compileFiles(specFileProvider.files())
  
    const outputPath = path.resolve(compilerOptions.cwd, 'elm-stuff', 'elm-spec.js')
    fs.writeFileSync(outputPath, compiledCode)
    return outputPath
  }
  
  return {
    compile
  }

}

CompilerFactory.$inject = ['config', 'elmSpec:fileProvider']

module.exports = {
  CompilerFactory
}