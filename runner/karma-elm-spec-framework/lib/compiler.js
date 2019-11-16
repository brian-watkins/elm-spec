const Compiler = require('elm-spec-core/src/compiler')
const path = require('path')
const fs = require('fs')

exports.compile = function(specPath) {
  const compiler = new Compiler({
    cwd: './sample',
    specPath,
    elmPath: '/Users/bwatkins/work/elm-spec/node_modules/.bin/elm',
    tags: []
  })

  const compiledCode = compiler.compile()
  fs.writeFileSync('elm.js', compiledCode)

  return path.join(__dirname, '../elm.js')
}