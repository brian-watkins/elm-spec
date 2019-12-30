
(function(window) {

  const KarmaReporter = require('./karmaReporter')
  const { SuiteRunner, ElmContext } = require('elm-spec-core')

  const defaultConfig = {
    tags: [],
    endOnFailure: false
  }

  const options = Object.assign(defaultConfig, window.__karma__.config.elmSpec)

  const context = new ElmContext(window)

  window.__karma__.start = function() {
    const reporter = new KarmaReporter(window.__karma__)
    const runner = new SuiteRunner(context, reporter, options)
    runner.runAll()
  }

})(window)

