const path = require('path')
const fs = require('fs')

exports.find = (elmJsonPath) => {
  const elmJson = JSON.parse(fs.readFileSync(elmJsonPath))
  const specRoot = path.dirname(elmJsonPath)
  const globs = elmJson["source-directories"].map(f => path.join(specRoot, f, "**/*.elm"))
  return {
    globs
  }
}