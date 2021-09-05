const { Command, flags } = require('@oclif/command')
const commandExists = require('command-exists').sync
const process = require('process')
const path = require('path')
const fs = require('fs')
const os = require('os')
const { SuiteRunner } = require('elm-spec-core')
const Compiler = require('elm-spec-core/compiler')
const ConsoleReporter = require('./consoleReporter')
const JSDOMSpecRunner = require('./jsdomSpecRunner')
const BrowserSpecRunner = require('./browserSpecRunner')
const RunSpecsCommand = require('./runSpecsCommand')
const FileWatcher = require('./fileWatcher')
const ElmFiles = require('./elmFiles')
const FileLoader = require('./fileLoader')
const PerformanceTimer = require('./performanceTimer')

class RunSuite extends Command {
  async run() {
    const { flags } = this.parse(RunSuite)

    const elmPath = flags.elm || "elm"
    if (!commandExists(elmPath)) {
      this.error(`No elm executable found at: ${elmPath}`)
    }

    const elmJsonPath = path.join(flags.specRoot, "elm.json")

    if (!fs.existsSync(elmJsonPath)) {
      this.error(`Expected an elm.json at: ${elmJsonPath}\nCheck the --specRoot flag to set the directory containing the elm.json for your specs.`)
    }

    const fileLoader = new FileLoader(flags.specRoot)

    const command = new RunSpecsCommand(
      this.compilerFor(flags),
      this.runnerFor(flags.browser, fileLoader),
      this.getReporter(),
      FileWatcher
    )

    const result = await command.execute({
      browserOptions: {
        visible: flags.visible,
        cssFiles: flags.css || []
      },
      runOptions: {
        endOnFailure: flags.endOnFailure,
        parallelSegments: flags.parallel ? numberOfCPUs() : 1
      },
      watchOptions: flags.watch ? ElmFiles.find(elmJsonPath) : { globs: [] }
    })

    if (completedWithRejectedScenarios(result)) {
      this.exit(1)
    }

    if (unableToCompleteDueToError(result)) {
      this.exit(2)
    }
  }

  compilerFor(flags) {
    return new Compiler({
      cwd: flags.specRoot,
      specPath: flags.specs,
      elmPath: flags.elm,
      logLevel: Compiler.LOG_LEVEL.QUIET
    })
  }

  runnerFor(browser, fileLoader) {
    switch (browser) {
      case "jsdom":
        return new JSDOMSpecRunner(fileLoader)
      default:
        return new BrowserSpecRunner(browser, fileLoader)
    }
  }

  getReporter() {
    return new ConsoleReporter(new PerformanceTimer(), {
      write: (c) => process.stdout.write(c),
      writeLine: this.log,
      stream: process.stdout
    })
  }
}

const numberOfCPUs = () => {
  return os.cpus().length
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
  elm: flags.string({description: 'path to elm'}),
  endOnFailure: flags.boolean({description: 'end spec suite run on first failure'}),
  browser: flags.string({
    description: 'browser environment for specs',
    options: ['jsdom', 'chromium', 'webkit', 'firefox'],
    default: 'jsdom'
  }),
  visible: flags.boolean({description: 'show browser while running specs (does nothing for jsdom)'}),
  watch: flags.boolean({
    description: "watch all elm files in the source-directories of the specRoot elm.json"
  }),
  parallel: flags.boolean({
    description: `run scenarios in parallel, up to ${numberOfCPUs()} at a time`
  }),
  css: flags.string({
    description: "path to .css file to load in the browser (may specify multiple)",
    multiple: true
  })
}

const completedWithRejectedScenarios = (result) => {
  return result.status === SuiteRunner.STATUS.OK && result.rejected > 0
}

const unableToCompleteDueToError = (result) => {
  return result.status === SuiteRunner.STATUS.ERROR
}

module.exports = RunSuite
