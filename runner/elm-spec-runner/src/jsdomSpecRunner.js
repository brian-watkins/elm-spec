const { JSDOM } = require("jsdom");
const { Compiler, BrowserContext } = require('elm-spec-core')
const path = require('path')
const fs = require('fs')

module.exports = class JSDOMSpecRunner {
  async start() {}

  async run(reporter, compilerOptions, runnerOptions) {
    const dom = this.getDom(compilerOptions.cwd)

    this.adaptForElmSpec(dom.window)

    this.adaptReporter(dom.window, reporter)

    await reporter.performAction("Compiling Elm ... ", "Done!", async () => {
      return this.prepareElm(dom, compilerOptions)
    })

    await dom.window._elm_spec.run(runnerOptions)
  }

  async stop() {}

  getDom(rootDir) {
    const dom = new JSDOM(
      "<html><head><base href='http://elm-spec'></head><body></body></html>",
      { pretendToBeVisual: true,
        runScripts: "dangerously",
        url: "http://elm-spec"
      }
    )

    const browserContext = new BrowserContext({ rootDir })
    browserContext.decorateWindow((name, fun) => {
      dom.window[name] = fun
    })

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

  prepareElm(dom, options) {
    const compiler = new Compiler(options)
    const code = compiler.compile()
    dom.window.eval(code)
    return dom.window.hasOwnProperty("Elm")
  }
}