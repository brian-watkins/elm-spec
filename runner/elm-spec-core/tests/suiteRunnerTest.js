const chai = require('chai')
const expect = chai.expect
const Compiler = require('../src/compiler')
const JsdomContext = require('../../elm-spec-runner/src/jsdomContext')
const SuiteRunner = require('../src/suiteRunner')

describe("Suite Runner", () => {
  it("runs a suite of tests", (done) => {
    expectPassingScenarios('specs', 8, [], done)
  })

  it("runs only the tagged scenarios", (done) => {
    expectPassingScenarios('specs', 3, [ "tagged" ], done)
  })

  context("when the suite should end on the first failure", () => {
    it("stops at the first failure", (done) => {
      expectScenarios('specsWithFailure', { tags: [], timeout: 50, endOnFailure: true }, done, (observations) => {
        expect(observations).to.have.length(3)
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejected(observations[2])
      })
    })
  })

  context("when the suite should report all results", () => {
    it("reports all results", (done) => {
      expectScenarios('specsWithFailure', { tags: [], timeout: 50, endOnFailure: false }, done, (observations) => {
        expect(observations).to.have.length(4)
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejected(observations[2])
        expectAccepted(observations[3])
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

  context("when the expected ports are not found", () => {
    context("when the sendOut port is not found", () => {
      it("reports an error", (done) => {
        expectScenariosAt({ cwd: './tests/badRunnerSample', specPath: './specs/*Spec.elm' }, { tags: [], timeout: 50, endOnFailure: false }, done, (observations, error) => {
          expect(observations).to.have.length(0)
          expect(error).to.deep.equal([
            reportLine("No sendOut port found!"),
            reportLine("Make sure your elm-spec program uses a port defined like so", "port sendOut : Message -> Cmd msg")
          ])
        })
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

const expectScenariosAt = (compilerOptions, options, done, matcher) => {
  const compiler = new Compiler(compilerOptions)
  
  const context = new JsdomContext(compiler)
  const reporter = new TestReporter()
  
  const runner = new SuiteRunner(context, reporter, options)
  runner
    .on('complete', () => {
      setTimeout(() => {
        matcher(reporter.observations, reporter.specError)
        done()
      }, 0)
    })
    .runAll()
}

const expectScenarios = (specDir, options, done, matcher) => {
  expectScenariosAt({
    cwd: './tests/sample',
    specPath: `./${specDir}/**/*Spec.elm`
  }, options, done, matcher)
}

const TestReporter = class {
  constructor() {
    this.observations = []
    this.specError = null
  }

  startSuite() {
    // Nothing
  }

  record(observation) {
    this.observations.push(observation)
  }

  finish() {}

  error(err) {
    this.specError = err
  }
}

const expectAccepted = (observation) => {
  expect(observation.summary).to.equal("ACCEPT")
}

const expectRejected = (observation) => {
  expect(observation.summary).to.equal("REJECT")
}

const reportLine = (statement, detail = null) => ({
  statement,
  detail
})
