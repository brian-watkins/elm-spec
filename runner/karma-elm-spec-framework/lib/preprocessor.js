const compiler = require('./compiler')

const create = (config) => {
  let processedFiles = {}

  return (content, file, done) => {
    // skip on initial load
    if (!processedFiles[file.path]) {
      processedFiles[file.path] = true
      done(null, "")
      return
    }

    compiler.compile(config.elmSpec)

    done(null, "")
  }
}
create.$inject = [
  'config'
]

module.exports = {
  create
}