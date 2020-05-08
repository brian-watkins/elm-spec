const { Command, flags } = require('@oclif/command')
const commandExists = require('command-exists').sync
const process = require('process')
const path = require('path')
const fs = require('fs')
const { Compiler } = require('elm-spec-core')
const ConsoleReporter = require('./consoleReporter')
const JSDOMSpecRunner = require('./jsdomSpecRunner')
const BrowserSpecRunner = require('./browserSpecRunner')
const RunSpecsCommand = require('./runSpecsCommand')
const FileWatcher = require('./fileWatcher')
const ElmFiles = require('./elmFiles')

class RunSuite extends Command {
  async run() {
    const { flags } = this.parse(RunSuite)

    if (!commandExists(flags.elm)) {
      this.error(`No elm executable found at: ${flags.elm}`)
    }

    const elmJsonPath = path.join(flags.specRoot, "elm.json")

    if (!fs.existsSync(elmJsonPath)) {
      this.error(`Expected an elm.json at: ${elmJsonPath}\nCheck the --specRoot flag to set the directory containing the elm.json for your specs.`)
    }

    const command = new RunSpecsCommand(this.runnerFor(flags.browser), this.getReporter(), FileWatcher)

    await command.execute({
      browserOptions: {
        visible: flags.visible
      },
      compilerOptions: {
        cwd: flags.specRoot,
        specPath: flags.specs,
        elmPath: flags.elm,
        logLevel: Compiler.LOG_LEVEL.QUIET
      },
      runOptions: {
        tags: flags.tag || [],
        endOnFailure: flags.endOnFailure
      },
      watchOptions: flags.watch ? ElmFiles.find(elmJsonPath) : { globs: [] }
    })
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
      writeLine: this.log,
      stream: process.stdout
    })
  }
}

RunSuite.description = `Run Elm-Spec specs from the command line`

RunSuite.flags = {
  version: flags.version({char: 'v'}),
  help: flags.help({char: 'h'}),
  specRoot: flags.string({
    description: 'root dir for specs containing elm.json',
    default: path.join(process.cwd(), "specs")
  }),
  specs: flags.string({
    description: 'glob for spec modules (relative to specRoot)',
    default: path.join(".", "**", "*Spec.elm")
  }),
  elm: flags.string({description: 'path to elm', default: 'elm'}),
  tag: flags.string({
    description: 'execute scenarios with this tag only (may specify multiple)',
    multiple: true
  }),
  endOnFailure: flags.boolean({description: 'end spec suite run on first failure'}),
  browser: flags.string({
    description: 'browser environment for specs',
    options: ['jsdom', 'chromium', 'webkit', 'firefox'],
    default: 'jsdom'
  }),
  visible: flags.boolean({description: 'show browser while running specs (does nothing for jsdom)'}),
  watch: flags.boolean({
    description: "watch all elm files in the source-directories of the specRoot elm.json"
  })
}

module.exports = RunSuite
