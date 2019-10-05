const chai = require('chai')
const expect = chai.expect
const Compiler = require('../elm-spec-runner/src/spec/compiler')
const HtmlContext = require('../elm-spec-runner/src/spec/htmlContext')
const SuiteRunner = require('../elm-spec-core/src/suiteRunner')
const process = require('process')

describe("Suite Runner", () => {
  it("runs a suite of tests", (done) => {
    const workDir = process.cwd()
    process.chdir('./runner/tests/sample')
    
    const compiler = new Compiler({
      specPath: "./specs/**/*Spec.elm"
    })
    
    const htmlContext = new HtmlContext(compiler)
    const reporter = new TestReporter()
    
    const runner = new SuiteRunner(htmlContext, reporter)
    runner
      .on('complete', () => {
        setTimeout(() => {
          expect(reporter.observations).to.equal(6)
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