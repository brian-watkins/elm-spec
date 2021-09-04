const ElmContext = require('elm-spec-core/src/elmContext')
const SuiteRunner = require('elm-spec-core/src/suiteRunner')
const BrowserReporter = require('./browserReporter')

const elmContext = new ElmContext(window)

window._elm_spec_run = (options, segment) => {
  return new Promise((resolve) => {
    const reporter = new BrowserReporter()
  
    new SuiteRunner(elmContext, reporter, options)
      .on('complete', resolve)
      .runSegment(segment, options.parallelSegments)
  })
}
