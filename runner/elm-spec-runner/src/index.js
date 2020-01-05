const { Command, flags } = require('@oclif/command')
const { Compiler, SuiteRunner, ElmContext } = require('elm-spec-core')
const Reporter = require('./consoleReporter')
const JsdomContext = require('./jsdomContext')
const commandExists = require('command-exists').sync
const glob = require("glob")
const process = require('process')
const path = require('path')

class ElmSpecRunnerCommand extends Command {
  async run() {
    const {flags} = this.parse(ElmSpecRunnerCommand)

    if (!commandExists(flags.elm)) {
      this.error(`No elm executable found at: ${flags.elm}`)
    }

    const specPath = flags.specs
    if (glob.sync(specPath, { cwd: flags.cwd }).length == 0) {
      this.error(`No spec modules found matching: ${specPath}`)
    }    

    const tags = flags.tag || []

    this.runSpecs({
      cwd: flags.cwd,
      specPath,
      elmPath: flags.elm,
      runnerOptions: {
        tags,
        endOnFailure: flags.endOnFailure
      }
    })
  }

  runSpecs(options) {
    const jsdom = new JsdomContext()
    const context = new ElmContext(jsdom.window)
    const reporter = new Reporter((c) => process.stdout.write(c), this.log)
    const runner = new SuiteRunner(context, reporter, options.runnerOptions)

    const compiler = new Compiler(options)
    jsdom.loadElm(compiler)

    runner.runAll()

    if (reporter.hasError) {
      process.exit(1)
    }
  }
}

ElmSpecRunnerCommand.description = `Run Elm-Spec specs from the command line`

ElmSpecRunnerCommand.flags = {
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

module.exports = ElmSpecRunnerCommand
