const chokidar = require('chokidar')

exports.watch = (filesToWatch, andThen) => {
  chokidar.watch(filesToWatch, {
    ignoreInitial: true
  }).on('all', async (event, path) => {
    andThen(path)
  })
}