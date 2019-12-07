const Compiler = require('elm-spec-core/src/compiler')
const path = require('path')
const fs = require('fs')

const defaultConfig = {
  cwd: process.cwd(),
  specPath: path.join(".", "specs", "**", "*Spec.elm"),
  elmPath: "elm"
}

exports.compile = function(config) {
  const compilerOptions = Object.assign(defaultConfig, config)

  const compiler = new Compiler(compilerOptions)

  const compiledCode = compiler.compile()

  const outputPath = path.resolve(compilerOptions.cwd, 'elm-stuff', 'elm-spec.js')
  fs.writeFileSync(outputPath, compiledCode)
  return outputPath
}