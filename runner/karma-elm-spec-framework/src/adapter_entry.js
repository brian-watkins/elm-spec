
(function(window) {

  const BrowserContext = require('./browserContext')
  const KarmaReporter = require('./karmaReporter')
  const SuiteRunner = require('elm-spec-core')

  const defaultConfig = {
    tags: [],
    endOnFailure: false,
    timeout: 5000,
    karmaPort: 9876
  }

  const options = Object.assign(defaultConfig, window.__karma__.config.elmSpec)

  const context = new BrowserContext(window)

  const base = document.createElement("base")
  base.setAttribute("href", `http://localhost:${options.karmaPort}`)
  window.document.head.appendChild(base)

  window.__karma__.start = function() {
    const reporter = new KarmaReporter(window.__karma__)
    const runner = new SuiteRunner(context, reporter, options)
    runner.runAll()
  }

})(window)

