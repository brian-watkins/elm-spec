const create = (compiler) => {
  let processedFiles = {}

  return (content, file, done) => {
    // skip on initial load
    if (!processedFiles[file.path]) {
      processedFiles[file.path] = true
      done(null, "")
      return
    }

    compiler.compile()

    done(null, "")
  }
}
create.$inject = [
  'elmSpec:compiler'
]

module.exports = {
  create
}