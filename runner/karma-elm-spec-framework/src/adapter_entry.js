
(function(window) {

  const BrowserContext = require('./browserContext')
  const KarmaReporter = require('./karmaReporter')
  const SuiteRunner = require('elm-spec-core')
  const FakeLocation = require('./fakes/fakeLocation')
  const FakeHistory = require('./fakes/fakeHistory')
  const { proxiedConsole } = require('./fakes/proxiedConsole')
  const { fakeWindow } = require('./fakes/fakeWindow')
  const { fakeDocument } = require('./fakes/fakeDocument')

  window._elm_spec = {}
  const fakeLocation = new FakeLocation((msg) => console.log("send to program", msg))
  window._elm_spec.window = fakeWindow(window, fakeLocation)
  window._elm_spec.document = fakeDocument(window, fakeLocation)
  window._elm_spec.history = new FakeHistory(fakeLocation)
  window._elm_spec.console = proxiedConsole()  

  const base = document.createElement("base")
  //NOTE: This has to be the right port!
  base.setAttribute("href", "http://localhost:9876")
  window.document.head.appendChild(base)

  window.__karma__.start = function(config) {
    console.log("START", config)
  
    console.log("elm", Elm)
  
    const context = new BrowserContext(window, [])
    const reporter = new KarmaReporter(window.__karma__)
  
    const runner = new SuiteRunner(context, reporter, { timeout: 5000 })
    runner.run()
  }

})(window)

