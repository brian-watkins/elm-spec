const browserify = require('browserify');
const path = require('path')

exports.bundleRunnerCode = () => {
  const b = browserify();
  b.add(path.join(__dirname, "specRunner.js"));
  
  return new Promise((resolve, reject) => {  
    let bundle = ''
    const stream = b.bundle()
    stream.on('data', function(data) {
      bundle += data.toString()
    })
    stream.on('end', function() {
      resolve(bundle)
    })
  })
}
