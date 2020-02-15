const glob = require('glob')

var SpecFileProvider = function(config) {
  this.findFiles = function() {
    this.specFiles = glob.sync(config.elmSpec.specs, { cwd: config.elmSpec.cwd, absolute: true })
  }

  this.files = function() {
    return this.specFiles
  }
}

SpecFileProvider.$inject = ['config'];

module.exports = {
  SpecFileProvider
}