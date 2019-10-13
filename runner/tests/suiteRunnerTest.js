const chai = require('chai')
const expect = chai.expect
const Compiler = require('../elm-spec-runner/src/spec/compiler')
const HtmlContext = require('../elm-spec-runner/src/spec/htmlContext')
const SuiteRunner = require('../elm-spec-core/src/suiteRunner')
const process = require('process')

describe("Suite Runner", () => {
  it("runs a suite of tests", (done) => {
    expectPassingScenarios(6, [], done)
  })

  it("runs only the tagged scenarios", (done) => {
    expectPassingScenarios(2, [ "tagged" ], done)
  })
})

const expectPassingScenarios = (number, tags, done) => {
  const workDir = process.cwd()
  process.chdir('./runner/tests/sample')
  
  const compiler = new Compiler({
    specPath: "./specs/**/*Spec.elm"
  })
  
  const htmlContext = new HtmlContext(compiler, tags)
  const reporter = new TestReporter()
  
  const runner = new SuiteRunner(htmlContext, reporter)
  runner
    .on('complete', () => {
      setTimeout(() => {
        process.chdir(workDir)
        expect(reporter.observations).to.have.length(number)
        reporter.observations.forEach(observation => {
          expect(observation.summary).to.equal("ACCEPT")
        })
        done()  
      }, 0)
    })
    .run()
}

const TestReporter = class {
  constructor() {
    this.observations = []
  }

  record(observation) {
    this.observations.push(observation)
  }

  finish() {}

  error(err) {
    throw err
  }
}