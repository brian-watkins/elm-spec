const {Command, flags} = require('@oclif/command')
const Compiler = require('./spec/compiler')
const Reporter = require('./spec/consoleReporter')
const HtmlContext = require('./spec/htmlContext')
const SuiteRunner = require('elm-spec-core')

class ElmSpecRunnerCommand extends Command {
  async run() {
    const compiler = new Compiler({
      specPath: "./specs/**/*Spec.elm",
      elmPath: "../../../node_modules/.bin/elm"
    })

    const htmlContext = new HtmlContext(compiler)
    const reporter = new Reporter(this.log)

    const runner = new SuiteRunner(htmlContext, reporter)
    runner.run()


    // const {flags} = this.parse(ElmSpecRunnerCommand)
    // const name = flags.name || 'world'
    // this.log(`hello ${name} from ./src/index.js`)
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
  // name: flags.string({char: 'n', description: 'name to print'}),
}

module.exports = ElmSpecRunnerCommand
