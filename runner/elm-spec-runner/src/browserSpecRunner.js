const Playwright = require('playwright')
const path = require('path')
const fs = require('fs')


module.exports = class BrowserSpecRunner {
  constructor(browserName, fileLoader) {
    this.browserName = browserName
    this.fileLoader = fileLoader
  }

  async start(options) {
    this.browserOptions = options
    this.browser = await Playwright[this.browserName].launch({
      headless: !options.visible
    })
  }

  async run(runOptions, compiledSpecs, reporter) {
    const browsers = await this.getBrowsersForSegments(runOptions.parallelSegments, reporter, compiledSpecs)

    await Promise.all(browsers.map(this.runSpecInBrowser(runOptions)))

  }

  async getBrowsersForSegments(segmentCount, reporter, compiledElm) {
    const browserContext = await this.getBrowserContext()

    const browsers = []
    for (let i = 0; i < segmentCount; i++) {
      const browser = await this.prepareBrowser(browserContext, reporter, compiledElm)
      browsers.push(browser)
    }

    return browsers
  }

  runSpecInBrowser(runnerOptions) {
    return (browser, index) => {
      return browser.evaluate((options) => {
        return window._elm_spec.run(options.runnerOptions, options.segment)
      }, { runnerOptions, segment: index })
    }
  }

  async stop() {
    await this.browser.close()
  }

  async prepareBrowser(browserContext, reporter, compiledElm) {
    const page = await this.getPage(browserContext)
    await this.loadCSS(page)
    await this.adaptPageForElm(page)
    await this.adaptReporterToBrowser(page, reporter)
    await this.prepareElm(page, compiledElm)
    return page
  }

  async loadCSS(page) {
    await Promise.all(this.browserOptions.cssFiles.map(path => page.addStyleTag({path})))
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

  async prepareElm(page, compiledCode) {
    await page.evaluate(compiledCode)
    return await page.evaluate(() => {
      return window.hasOwnProperty("Elm")
    })
  }

  async getBrowserContext() {
    if (this.browser.contexts().length > 0) {
      this.browser.contexts().map(async (context) => await context.close())
    }

    return this.browser.newContext()
  }

  async getPage(context) {
    const page = await context.newPage()

    page.on('console', async (msg) => {
      const logParts = await Promise.all(msg.args().map((arg) => arg.jsonValue()))
      if (logParts.length == 0) return
      console.log(...logParts)
    });

    page.on('pageerror', async (err) => {
      console.log(err)
    })

    await this.fileLoader.decorateWindow(async (name, fun) => {
      await page.exposeFunction(name, fun)
    })

    return page
  }
}