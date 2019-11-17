
(function(window) {

  const BrowserContext = require('./browserContext')
  const KarmaReporter = require('./karmaReporter')
  const SuiteRunner = require('elm-spec-core')

  const defaultConfig = {
    tags: []
  }

  const elmSpecConfig = window.__karma__.config.elmSpec || defaultConfig

  const context = new BrowserContext(window, elmSpecConfig.tags)

  const base = document.createElement("base")
  //NOTE: This has to be the right port!
  base.setAttribute("href", "http://localhost:9876")
  window.document.head.appendChild(base)

  window.__karma__.start = function() {
    const reporter = new KarmaReporter(window.__karma__)
    const runner = new SuiteRunner(context, reporter, { timeout: 5000 })
    runner.run()
  }

})(window)

