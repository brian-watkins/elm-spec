const { ElmContext, SuiteRunner } = require('../../src/index')
const TestReporter = require('./testReporter')

const elmContext = new ElmContext(window)

const base = document.createElement("base")
base.setAttribute("href", "http://localhost")
window.document.head.appendChild(base)

window._elm_spec_run = (options, version) => {
  return new Promise((resolve, reject) => {
    const reporter = new TestReporter()

    new SuiteRunner(elmContext, reporter, options, version)
      .on('complete', (result) => {
        resolve({ result, reporter })
      })
      .runAll()
  })
}
