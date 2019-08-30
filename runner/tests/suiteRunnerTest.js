const chai = require('chai')
const expect = chai.expect
const Compiler = require('../src/node-runner/compiler')
const HtmlContext = require('../src/node-runner/htmlContext')
const SuiteRunner = require('../src/core/suiteRunner')
const process = require('process')

describe("Suite Runner", () => {
  it("runs a suite of tests", (done) => {
    const workDir = process.cwd()
    process.chdir('./runner/tests/sample')
    
    const compiler = new Compiler({
      specPath: "./specs/**/*Spec.elm",
      elmPath: "../../../node_modules/.bin/elm"
    })
    
    const htmlContext = new HtmlContext(compiler)
    const reporter = new TestReporter()
    
    const runner = new SuiteRunner(htmlContext, reporter)
    runner
      .on('complete', () => {
        setTimeout(() => {
          expect(reporter.observations).to.equal(5)
          process.chdir(workDir)
          done()  
        }, 0)
      })
      .run()
  })
})

const TestReporter = class {
  constructor() {
    this.observations = 0
  }

  record(observation) {
    this.observations++
  }

  finish() {}

  error(err) {
    throw err
  }
}