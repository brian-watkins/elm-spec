const {Command, flags} = require('@oclif/command')
const Compiler = require('./spec/compiler')
const Reporter = require('./spec/consoleReporter')
const HtmlContext = require('./spec/htmlContext')
const SuiteRunner = require('elm-spec-core')
const commandExists = require('command-exists').sync
const glob = require("glob")

class ElmSpecRunnerCommand extends Command {
  async run() {
    const {flags} = this.parse(ElmSpecRunnerCommand)
    
    const elmPath = flags.elm || 'elm'
    if (!commandExists(elmPath)) {
      if (flags.elm) {
        this.error(`No elm executable found at: ${flags.elm}`)
      } else {
        this.error('No elm executable found in the current path')
      }
    }

    const specPath = flags.specs || './specs/**/*Spec.elm'
    if (glob.sync(specPath).length == 0) {
      this.error(`No spec modules found matching: ${specPath}`)
    }    

    this.runSpecs({
      specPath,
      elmPath
    })
  }

  runSpecs(options) {
    const compiler = new Compiler(options)

    const htmlContext = new HtmlContext(compiler)
    const reporter = new Reporter(this.log)

    const runner = new SuiteRunner(htmlContext, reporter)
    runner.run()
  }
}

ElmSpecRunnerCommand.description = `Run Elm-Spec specs from the command line
...
Extra documentation goes here
`

ElmSpecRunnerCommand.flags = {
  // add --version flag to show CLI version
  version: flags.version({char: 'v'}),
  // add --help flag to show CLI version
  help: flags.help({char: 'h'}),
  elm: flags.string({char: 'e', description: 'path to elm'}),
  specs: flags.string({char: 's', description: 'glob for spec modules'})
}

module.exports = ElmSpecRunnerCommand
