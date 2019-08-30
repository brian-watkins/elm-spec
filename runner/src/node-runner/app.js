const Compiler = require('./compiler')
const Reporter = require('./consoleReporter')
const HtmlContext = require('./htmlContext')
const SuiteRunner = require('../core/suiteRunner')

const compiler = new Compiler({
  specPath: "./specs/**/*Spec.elm",
  elmPath: "../../../node_modules/.bin/elm"
})

const htmlContext = new HtmlContext(compiler)
const reporter = new Reporter(console.log)

const runner = new SuiteRunner(htmlContext, reporter)
runner.run()
