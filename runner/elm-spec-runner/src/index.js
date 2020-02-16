const { Command, flags } = require('@oclif/command')
const { Compiler, SuiteRunner } = require('elm-spec-core')
const ConsoleReporter = require('./consoleReporter')
const { loadElmContext } = require('./jsdomContext')
const commandExists = require('command-exists').sync
const process = require('process')
const path = require('path')

class RunSuite extends Command {
  async run() {
    const {flags} = this.parse(RunSuite)

    if (!commandExists(flags.elm)) {
      this.error(`No elm executable found at: ${flags.elm}`)
    }

    const tags = flags.tag || []

    await this.runSpecs({
      compilerOptions: {
        cwd: flags.cwd,
        specPath: flags.specs,
        elmPath: flags.elm,
      },
      runnerOptions: {
        tags,
        endOnFailure: flags.endOnFailure
      }
    })
  }

  async runSpecs({ compilerOptions, runnerOptions }) {
    const elmContext = this.getElmContext(compilerOptions)
    const reporter = this.getReporter()

    await new Promise((resolve) => {
      new SuiteRunner(elmContext, reporter, runnerOptions)
        .on('complete', () => {
          if (reporter.hasError) {
            this.exit(1)
          }

          resolve()
        })
        .runAll()
    })
  }

  getElmContext(options) {
    const compiler = new Compiler(options)
    return loadElmContext(compiler)
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
  // add --version flag to show CLI version
  version: flags.version({char: 'v'}),
  // add --help flag to show CLI version
  help: flags.help({char: 'h'}),
  cwd: flags.string({char: 'c', description: 'current working directory', default: path.join(process.cwd(), "specs")}),
  specs: flags.string({char: 's', description: 'glob for spec modules', default: path.join(".", "**", "*Spec.elm")}),
  elm: flags.string({char: 'e', description: 'path to elm', default: 'elm'}),
  tag: flags.string({char: 't', description: 'execute scenarios with this tag only (may specify multiple)', multiple: true}),
  endOnFailure: flags.boolean({char: 'f', description: 'end spec suite run on first failure', default: false}),
}

module.exports = RunSuite
