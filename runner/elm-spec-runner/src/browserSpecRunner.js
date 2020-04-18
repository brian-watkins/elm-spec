const Playwright = require('playwright')
const { Compiler } = require('elm-spec-core')
const path = require('path')
const fs = require('fs')


module.exports = class BrowserSpecRunner {
  constructor(browserName) {
    this.browserName = browserName
  }

  async init(options) {
    this.browserOptions = options
    this.browser = await Playwright[this.browserName].launch({
      headless: !options.visible
    })
  }

  async run(reporter, compilerOptions, runnerOptions) {
    const page = await this.getPage()

    await this.adaptReporterToBrowser(page, reporter)

    await this.compile(page, compilerOptions)

    await page.evaluate((options) => {
      return window._elm_spec.run(options)
    }, runnerOptions)
  }

  async close() {
    await this.browser.close()
  }

  async adaptReporterToBrowser(page, reporter) {
    await page.exposeFunction('_elm_spec_reporter_start', () => { reporter.startSuite() })
    await page.exposeFunction('_elm_spec_reporter_observe', (obs) => { reporter.record(obs) })
    await page.exposeFunction('_elm_spec_reporter_log', (report) => { reporter.log(report) })
    await page.exposeFunction('_elm_spec_reporter_error', (err) => { reporter.error(err) })
    await page.exposeFunction('_elm_spec_reporter_finish', () => { reporter.finish() })
  }

  async compile(page, options) {
    const compiler = new Compiler(options)
    const compiledCode = compiler.compile()
    await page.evaluate(compiledCode)
  }

  async getPage() {
    const context = await this.browser.newContext()
    const page = await context.newPage()

    page.on('console', async (msg) => {
      const logParts = await Promise.all(msg.args().map((arg) => arg.jsonValue()))
      console.log(...logParts)
    });

    page.on('pageerror', async (err) => {
      console.log(err)
    })

    const browserAdapter = path.join(__dirname, 'browserAdapter.js')
    const bundle = fs.readFileSync(browserAdapter, "utf8")
    await page.evaluate(bundle)

    return page
  }
}