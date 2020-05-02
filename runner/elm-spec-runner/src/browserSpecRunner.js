const Playwright = require('playwright')
const { Compiler, BrowserContext } = require('elm-spec-core')
const path = require('path')
const fs = require('fs')


module.exports = class BrowserSpecRunner {
  constructor(browserName) {
    this.browserName = browserName
  }

  async start(options) {
    this.browserOptions = options
    this.browser = await Playwright[this.browserName].launch({
      headless: !options.visible
    })
  }

  async run(reporter, compilerOptions, runnerOptions) {
    const page = await this.getPage(compilerOptions.cwd)

    await this.adaptPageForElm(page)

    await this.adaptReporterToBrowser(page, reporter)

    await reporter.performAction("Compiling Elm ... ", "Done!", async () => {
      return this.prepareElm(page, compilerOptions)
    })

    await page.evaluate((options) => {
      return window._elm_spec.run(options)
    }, runnerOptions)
  }

  async stop() {
    await this.browser.close()
  }

  async adaptPageForElm(page) {
    const browserAdapter = path.join(__dirname, 'browserAdapter.js')
    const bundle = fs.readFileSync(browserAdapter, "utf8")
    await page.evaluate(bundle)
  }

  async adaptReporterToBrowser(page, reporter) {
    await page.exposeFunction('_elm_spec_reporter_start', () => { reporter.startSuite() })
    await page.exposeFunction('_elm_spec_reporter_observe', (obs) => { reporter.record(obs) })
    await page.exposeFunction('_elm_spec_reporter_log', (report) => { reporter.log(report) })
    await page.exposeFunction('_elm_spec_reporter_error', (err) => { reporter.error(err) })
    await page.exposeFunction('_elm_spec_reporter_finish', () => { reporter.finish() })
  }

  async prepareElm(page, options) {
    const compiler = new Compiler(options)
    const compiledCode = compiler.compile()
    await page.evaluate(compiledCode)
    return await page.evaluate(() => {
      return window.hasOwnProperty("Elm")
    })
  }

  async getPage(rootDir) {
    if (this.browser.contexts().length > 0) {
      this.browser.contexts().map(async (context) => await context.close())
    }

    const context = await this.browser.newContext()
    const page = await context.newPage()

    page.on('console', async (msg) => {
      const logParts = await Promise.all(msg.args().map((arg) => arg.jsonValue()))
      console.log(...logParts)
    });

    page.on('pageerror', async (err) => {
      console.log(err)
    })

    const browserContext = new BrowserContext({ rootDir })
    await browserContext.decorateWindow(async (name, fun) => {
      await page.exposeFunction(name, fun)
    })

    return page
  }
}