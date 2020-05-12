
(function(window) {

  const KarmaReporter = require('./karmaReporter')
  const SuiteRunner = require('elm-spec-core/src/suiteRunner')
  const ElmContext = require('elm-spec-core/src/elmContext')

  const defaultConfig = {
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

