const { Command, flags } = require('@oclif/command')
const ConsoleReporter = require('./consoleReporter')
const commandExists = require('command-exists').sync
const process = require('process')
const path = require('path')
const JSDOMSpecRunner = require('./jsdomSpecRunner')
const BrowserSpecRunner = require('./browserSpecRunner')

class RunSuite extends Command {
  async run() {
    const { flags } = this.parse(RunSuite)

    if (!commandExists(flags.elm)) {
      this.error(`No elm executable found at: ${flags.elm}`)
    }

    await this.runSpecs(flags.browser, {
      compilerOptions: {
        cwd: flags.cwd,
        specPath: flags.specs,
        elmPath: flags.elm,
      },
      runnerOptions: {
        tags: flags.tag || [],
        endOnFailure: flags.endOnFailure
      }
    })
  }

  async runSpecs(browser, { compilerOptions, runnerOptions }) {
    const runner = this.runnerFor(browser)
    await runner.init()
    await runner.run(this.getReporter(), compilerOptions, runnerOptions)
  }

  runnerFor(browser) {
    switch (browser) {
      case "jsdom":
        return new JSDOMSpecRunner()
      default:
        return new BrowserSpecRunner(browser)
    }
  }

  getReporter() {
    return new ConsoleReporter({
      write: (c) => process.stdout.write(c),
      writeLine: this.log
    })
  }
}

RunSuite.description = `Run Elm-Spec specs from the command line`

RunSuite.flags = {
  version: flags.version({char: 'v'}),
  help: flags.help({char: 'h'}),
  cwd: flags.string({char: 'c', description: 'current working directory', default: path.join(process.cwd(), "specs")}),
  specs: flags.string({char: 's', description: 'glob for spec modules', default: path.join(".", "**", "*Spec.elm")}),
  elm: flags.string({char: 'e', description: 'path to elm', default: 'elm'}),
  tag: flags.string({char: 't', description: 'execute scenarios with this tag only (may specify multiple)', multiple: true}),
  endOnFailure: flags.boolean({char: 'f', description: 'end spec suite run on first failure', default: false}),
  browser: flags.string({
    char: 'b',
    description: 'browser environment for specs',
    options: ['jsdom', 'chromium', 'webkit', 'firefox'],
    default: 'jsdom'
  })
}

module.exports = RunSuite
