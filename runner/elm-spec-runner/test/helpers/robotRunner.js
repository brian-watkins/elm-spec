const { chromium } = require('playwright');

module.exports = class RobotRunner {
  constructor(runner) {
    this.runner = runner
  }

  async start(options) {
    this.browser = await chromium.launch({
      headless: true
    })
    return this.runner.start(options)
  }

  async run(runnerOptions, compiledCode, reporter) {
    return new Promise((resolve) => {
      this.runner.run(runnerOptions, compiledCode, reporter).then((results) => {
        resolve(results)
      })
      if (!this.page) {
        this.browser.newPage().then((page) => {
          this.page = page
          page.goto(this.runner.specsURL())
        })
      }
    })
  }

  async stop() {
    await this.runner.stop()
    await this.page.close()
    this.page = null
    await this.browser.close()
  }
}