const path = require('path')
const preprocessor = require('./preprocessor')
const { ElmSpecReporter } = require('./elmSpecReporter')
const Compiler = require('elm-spec-core/src/compiler')
const fs = require('fs')

const createPattern = function (path) {
  return {pattern: path, included: true, served: true, watched: true}
}

const initElmSpec = function(files, config) {
  const specPath = files[0].pattern
  files[0].included = false
  files[0].served = false

  const compiler = new Compiler({
    cwd: './sample',
    specPath,
    elmPath: '/Users/bwatkins/work/elm-spec/node_modules/.bin/elm',
    tags: []
  })

  const compiledCode = compiler.compile()
  
  const preparedCode = "(function(actualWindow){const requestAnimationFrame = actualWindow._elm_spec.window.requestAnimationFrame; const console = actualWindow._elm_spec.console; const window = actualWindow._elm_spec.window; const history = actualWindow._elm_spec.history; const document = actualWindow._elm_spec.document; " + compiledCode + "})(window)"
  fs.writeFileSync("elm.js", preparedCode)

  files.unshift(createPattern(path.join(__dirname, '../elm.js')))
  files.unshift(createPattern(path.join(__dirname, 'adapter.js')))
}
initElmSpec.$inject = ["config.files", "config"];

module.exports = {
  "framework:elm-spec":["factory", initElmSpec],
  "preprocessor:elm-spec": ["factory", preprocessor.create],
  "reporter:elm-spec": ['type', ElmSpecReporter]
};
