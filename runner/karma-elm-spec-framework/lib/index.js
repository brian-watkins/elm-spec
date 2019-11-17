const path = require('path')
const preprocessor = require('./preprocessor')
const { ElmSpecReporter } = require('./elmSpecReporter')
const compiler = require('./compiler')


const createPattern = function (path) {
  return {pattern: path, included: true, served: true, watched: true}
}

const initElmSpec = function(files, config) {
  const compiledFile = compiler.compile(config.elmSpec)

  files.unshift(createPattern(compiledFile))
  files.unshift(createPattern(path.join(__dirname, 'adapter.js')))
}
initElmSpec.$inject = ["config.files", "config"];

module.exports = {
  "framework:elm-spec":["factory", initElmSpec],
  "preprocessor:elm-spec": ["factory", preprocessor.create],
  "reporter:elm-spec": ['type', ElmSpecReporter]
};
