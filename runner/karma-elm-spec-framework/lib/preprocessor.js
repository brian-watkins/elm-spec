const Compiler = require('elm-spec-core/src/compiler')
const fs = require('fs')

const create = (logger, files) => {
  const log  = logger.create("preprocessor.elm-spec")
  let processedFiles = {}

  return (content, file, done) => {
    // skip on initial load
    if (!processedFiles[file.path]) {
      processedFiles[file.path] = true
      done(null, "")
      return
    }

    const specPath = files[files.length - 1].pattern

    log.info("Compiling!", specPath)

    const compiler = new Compiler({
      cwd: './sample',
      specPath,
      elmPath: '/Users/bwatkins/work/elm-spec/node_modules/.bin/elm',
      tags: []
    })
  
    const compiledCode = compiler.compile()
    
    const preparedCode = "(function(actualWindow){const requestAnimationFrame = actualWindow._elm_spec.window.requestAnimationFrame; const console = actualWindow._elm_spec.console; const window = actualWindow._elm_spec.window; const history = actualWindow._elm_spec.history; const document = actualWindow._elm_spec.document; " + compiledCode + "})(window)"
    fs.writeFileSync("elm.js", preparedCode)
  
    done(null, "")
  }
}
create.$inject = [
  'logger',
  'config.files'
]

module.exports = {
  create
}