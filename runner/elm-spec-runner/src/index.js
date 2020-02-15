const { Command, flags } = require('@oclif/command')
const { Compiler, SuiteRunner } = require('elm-spec-core')
const ConsoleReporter = require('./consoleReporter')
const { loadElmContext } = require('./jsdomContext')
const commandExists = require('command-exists').sync
const glob = require("glob")
const process = require('process')
const path = require('path')

class RunSuite extends Command {
  async run() {
    const {flags} = this.parse(RunSuite)

    if (!commandExists(flags.elm)) {
      this.error(`No elm executable found at: ${flags.elm}`)
    }

    const specFiles = glob.sync(flags.specs, { cwd: flags.cwd, absolute: true })

    if (specFiles.length == 0) {
      this.error(`No spec modules found matching: ${flags.specs}`)
    }    

    const tags = flags.tag || []

    await this.runSpecs(specFiles, {
      compilerOptions: {
        cwd: flags.cwd,
        elmPath: flags.elm,
      },
      runnerOptions: {
        tags,
        endOnFailure: flags.endOnFailure
      }
    })
  }

  async runSpecs(specFiles, options) {
    const elmContext = this.getElmContext(specFiles, options.compilerOptions)
    const reporter = this.getReporter(specFiles)

    await new Promise((resolve) => {
      new SuiteRunner(elmContext, reporter, options.runnerOptions)
        .on('complete', () => {
          if (reporter.hasError) {
            process.exit(1)
          }

          resolve()
        })
        .runAll()
    })
  }

  getElmContext(specFiles, options) {
    const compiler = new Compiler(options)
    return loadElmContext(compiler)(specFiles)
  }

  getReporter(specFiles) {
    return new ConsoleReporter({
      write: (c) => process.stdout.write(c),
      writeLine: this.log, 
      specFiles
    })
  }
}

RunSuite.description = `Run Elm-Spec specs from the command line`

RunSuite.flags = {
  // add --version flag to show CLI version
  version: flags.version({char: 'v'}),
  // add --help flag to show CLI version
  help: flags.help({char: 'h'}),
  cwd: flags.string({char: 'c', description: 'current working directory', default: process.cwd()}),
  specs: flags.string({char: 's', description: 'glob for spec modules', default: path.join(".", "specs", "**", "*Spec.elm")}),
  elm: flags.string({char: 'e', description: 'path to elm', default: 'elm'}),
  tag: flags.string({char: 't', description: 'execute scenarios with this tag only (may specify multiple)', multiple: true}),
  endOnFailure: flags.boolean({char: 'f', description: 'end spec suite run on first failure', default: false}),
}

module.exports = RunSuite
