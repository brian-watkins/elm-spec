const { Command, flags } = require('@oclif/command')
const ConsoleReporter = require('./consoleReporter')
const commandExists = require('command-exists').sync
const process = require('process')
const path = require('path')
const JSDOMSpecRunner = require('./jsdomSpecRunner')
const BrowserSpecRunner = require('./browserSpecRunner')
const chokidar = require('chokidar')
const fs = require('fs')

class RunSuite extends Command {
  async run() {
    const { flags } = this.parse(RunSuite)

    if (!commandExists(flags.elm)) {
      this.error(`No elm executable found at: ${flags.elm}`)
    }

    const elmJsonPath = path.join(flags.cwd, "elm.json")

    if (!fs.existsSync(elmJsonPath)) {
      this.error(`Expected an elm.json at: ${elmJsonPath}\nCheck the --cwd flag to set the directory containing the elm.json for your specs.`)
    }

    let filesToWatch = flags.watch ? this.getFilesToWatch(flags.cwd, elmJsonPath) : []

    await this.runSpecs({
      browserOptions: {
        name: flags.browser,
        visible: flags.visible
      },
      compilerOptions: {
        cwd: flags.cwd,
        specPath: flags.specs,
        elmPath: flags.elm,
      },
      runnerOptions: {
        tags: flags.tag || [],
        endOnFailure: flags.endOnFailure
      }
    }, filesToWatch)
  }

  async runSpecs({ browserOptions, compilerOptions, runnerOptions }, filesToWatch) {
    const runner = this.runnerFor(browserOptions.name)
    await runner.init(browserOptions)

    if (filesToWatch.length > 0) {
      console.log("Files to watch", filesToWatch)
      chokidar.watch(filesToWatch, { ignoreInitial: true }).on('all', async (event, path) => {
        console.log("File changed", path)
        await runner.run(this.getReporter(), compilerOptions, runnerOptions)
      })
    }

    await runner.run(this.getReporter(), compilerOptions, runnerOptions)

    if (filesToWatch.length == 0 && !browserOptions.visible) {
      await runner.close()
    }
  }

  runnerFor(browser) {
    switch (browser) {
      case "jsdom":
        return new JSDOMSpecRunner()
      default:
        return new BrowserSpecRunner(browser)
    }
  }

  getFilesToWatch(specRoot, elmJsonPath) {
    const elmJson = JSON.parse(fs.readFileSync(elmJsonPath))
    return elmJson["source-directories"].map(f => path.join(specRoot, f, "**/*.elm"))
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
  cwd: flags.string({
    description: 'root dir for specs containing elm.json',
    default: path.join(process.cwd(), "specs")
  }),
  specs: flags.string({
    description: 'glob for spec modules',
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
