const path = require('path')
const preprocessor = require('./preprocessor')
const { ElmSpecReporter } = require('./elmSpecReporter')
const { CompilerFactory } = require('./compiler')


const createPattern = function (path) {
  return {pattern: path, included: true, served: true, watched: true}
}

const initElmSpec = function(files, config, compiler) {
  config.customContextFile = path.join(__dirname, "static", "context.thtml")
  config.customDebugFile = path.join(__dirname, "static", "debug.thtml")

  const compiledFile = compiler.compile()

  files.unshift(createPattern(compiledFile))
  files.unshift(createPattern(path.join(__dirname, 'adapter.js')))
}
initElmSpec.$inject = ["config.files", "config", "elmSpec:compiler"];

module.exports = {
  "framework:elm-spec":["factory", initElmSpec],
  "preprocessor:elm-spec": ["factory", preprocessor.create],
  "reporter:elm-spec": ['type', ElmSpecReporter],
  "elmSpec:compiler": [ 'factory', CompilerFactory ]
};
