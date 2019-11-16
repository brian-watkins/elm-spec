const compiler = require('./compiler')

const create = (files) => {
  let processedFiles = {}

  return (content, file, done) => {
    // skip on initial load
    if (!processedFiles[file.path]) {
      processedFiles[file.path] = true
      done(null, "")
      return
    }

    const specPath = files[files.length - 1].pattern

    compiler.compile(specPath)

    done(null, "")
  }
}
create.$inject = [
  'config.files'
]

module.exports = {
  create
}