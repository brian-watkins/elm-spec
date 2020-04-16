const SuiteRunner = require('elm-spec-core/src/suiteRunner')
const ElmContext = require('elm-spec-core/src/elmContext')
const BrowserReporter = require('./browserReporter')

const base = document.createElement("base")
base.setAttribute("href", "http://localhost")
window.document.head.appendChild(base)

const elmContext = new ElmContext(window)

window._elm_spec.run = (options) => {
  return new Promise((resolve) => {
    const reporter = new BrowserReporter()
  
    new SuiteRunner(elmContext, reporter, options)
      .on('complete', resolve)
      .runAll()
  })
}
