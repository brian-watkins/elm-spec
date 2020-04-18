const chokidar = require('chokidar')

let inFlight = false

exports.watch = (filesToWatch, andThen) => {
  chokidar.watch(filesToWatch, {
    ignoreInitial: true
  }).on('all', async (event, path) => {
    if (inFlight) return
    inFlight = true
    await andThen(path)
    inFlight = false
  })
}