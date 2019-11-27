const chai = require('chai')
const expect = chai.expect
const Compiler = require('elm-spec-core/src/compiler')
const JsdomContext = require('../elm-spec-runner/src/jsdomContext')
const SuiteRunner = require('elm-spec-core/src/suiteRunner')

describe("Suite Runner", () => {
  it("runs a suite of tests", (done) => {
    expectPassingScenarios('specs', 6, [], done)
  })

  it("runs only the tagged scenarios", (done) => {
    expectPassingScenarios('specs', 2, [ "tagged" ], done)
  })

  context("when the suite should end on the first failure", () => {
    it("stops at the first failure", (done) => {
      expectScenarios('specsWithFailure', { tags: [], timeout: 50, endOnFailure: true }, done, (observations) => {
        expect(observations).to.have.length(3)
        expect(observations[0].summary).to.equal("ACCEPT")
        expect(observations[1].summary).to.equal("ACCEPT")
        expect(observations[2].summary).to.equal("REJECT")
      })
    })
  })

  context("when the suite should report all results", () => {
    it("reports all results", (done) => {
      expectScenarios('specsWithFailure', { tags: [], timeout: 50, endOnFailure: false }, done, (observations) => {
        expect(observations).to.have.length(4)
        expect(observations[0].summary).to.equal("ACCEPT")
        expect(observations[1].summary).to.equal("ACCEPT")
        expect(observations[2].summary).to.equal("REJECT")
        expect(observations[3].summary).to.equal("ACCEPT")
      })
    })
  })
  
  context("when the code does not compile", () => {
    it("reports zero tests", (done) => {
      expectScenarios('specsWithCompilationError', { tags: [], timeout: 50, endOnFailure: false }, done, (observations) => {
        expect(observations).to.have.length(0)
      })
    })
  })

})

const expectPassingScenarios = (specDir, number, tags, done) => {
  expectScenarios(specDir, { tags: tags, timeout: 50, endOnFailure: false }, done, (observations) => {
    expect(observations).to.have.length(number)
    observations.forEach(observation => {
      expect(observation.summary).to.equal("ACCEPT")
    })
  })
}

const expectScenarios = (specDir, options, done, matcher) => {
  const compiler = new Compiler({
    cwd: './runner/tests/sample',
    specPath: `./${specDir}/**/*Spec.elm`
  })
  
  const context = new JsdomContext(compiler)
  const reporter = new TestReporter()
  
  const runner = new SuiteRunner(context, reporter, options)
  runner
    .on('complete', () => {
      setTimeout(() => {
        matcher(reporter.observations)
        done()
      }, 0)
    })
    .runAll()
}

const TestReporter = class {
  constructor() {
    this.observations = []
  }

  startSuite() {
    // Nothing
  }

  record(observation) {
    this.observations.push(observation)
  }

  finish() {}

  error(err) {
    throw err
  }
}