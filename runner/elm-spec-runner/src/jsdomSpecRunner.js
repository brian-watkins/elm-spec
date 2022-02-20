const { JSDOM } = require("jsdom");
const path = require('path')
const fs = require('fs')

module.exports = class JSDOMSpecRunner {
  constructor(fileLoader) {
    this.fileLoader = fileLoader
  }

  async start() {}

  async run(runOptions, compiledSpecs, reporter) {
    const browsers = this.getBrowsersForSegments(runOptions.parallelSegments, reporter, compiledSpecs)
    return await Promise.all(browsers.map(this.runSpecInBrowser(runOptions)))
  }

  async stop() {}

  runSpecInBrowser(runnerOptions) {
    return async (browser, index) => {
      return browser.window._elm_spec_run(runnerOptions, index)
    }
  }

  getBrowsersForSegments(segmentCount, reporter, compiledElm) {
    const browsers = []
    
    for (let i = 0; i < segmentCount; i++) {
      const dom = this.getDom()
      this.adaptForElmSpec(dom.window)
      this.adaptReporter(dom.window, reporter)
      this.prepareElm(dom, compiledElm)  
      browsers.push(dom)
    }

    return browsers
  }

  getDom() {
    const dom = new JSDOM(
      "<html><head></head><body></body></html>",
      { pretendToBeVisual: true,
        runScripts: "dangerously",
        url: "http://elm-spec",
        beforeParse: (window) => {
          this.fileLoader.decorateWindow((name, fun) => {
            window[name] = fun
          })
        }
      }
    )

    return dom
  }

  adaptForElmSpec(window) {
    const browserAdapter = path.join(__dirname, 'browserAdapter.js')
    const bundle = fs.readFileSync(browserAdapter, "utf8")
    window.eval(bundle)
  }

  adaptReporter(window, reporter) {
    window._elm_spec_reporter_start = () => { reporter.startSuite() }
    window._elm_spec_reporter_observe = (obs) => { reporter.record(obs) }
    window._elm_spec_reporter_log = (report) => { reporter.log(report) }
    window._elm_spec_reporter_error = (err) => { reporter.error(err) }
    window._elm_spec_reporter_finish = () => { reporter.finish() }
  }

  prepareElm(dom, compiledCode) {
    dom.window.eval(compiledCode)
  }
}