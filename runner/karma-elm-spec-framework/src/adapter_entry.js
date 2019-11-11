
(function(window) {

  const BrowserContext = require('./browserContext')
  const KarmaReporter = require('./karmaReporter')
  const SuiteRunner = require('elm-spec-core')
  const FakeLocation = require('elm-spec-core/src/fakes/fakeLocation')
  const FakeHistory = require('elm-spec-core/src/fakes/fakeHistory')
  const { proxiedConsole } = require('elm-spec-core/src/fakes/proxiedConsole')
  const { fakeWindow } = require('elm-spec-core/src/fakes/fakeWindow')
  const { fakeDocument } = require('elm-spec-core/src/fakes/fakeDocument')
  const lolex = require('lolex')

  window._elm_spec = {}
  const fakeLocation = new FakeLocation((msg) => console.log("send to program", msg))
  const clock = lolex.createClock()
  window._elm_spec.window = fakeWindow(window, fakeLocation, clock)
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
  
    const context = new BrowserContext(window, clock, [])
    const reporter = new KarmaReporter(window.__karma__)
  
    const runner = new SuiteRunner(context, reporter, { timeout: 5000 })
    runner.run()
  }

})(window)

