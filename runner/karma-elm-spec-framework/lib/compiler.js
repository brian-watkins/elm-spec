const Compiler = require('elm-spec-core/src/compiler')
const path = require('path')
const fs = require('fs')

exports.compile = function(config) {
  const compiler = new Compiler({
    cwd: config.specRoot,
    specPath: config.specs,
    elmPath: config.pathToElm,
  })

  const compiledCode = compiler.compile()

  const outputPath = path.resolve(config.specRoot, 'elm-stuff', 'elm-spec.js')
  fs.writeFileSync(outputPath, compiledCode)
  return outputPath
}