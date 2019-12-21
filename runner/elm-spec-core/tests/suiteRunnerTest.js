const chai = require('chai')
const expect = chai.expect
const Compiler = require('../src/compiler')
const JsdomContext = require('../../elm-spec-runner/src/jsdomContext')
const SuiteRunner = require('../src/suiteRunner')
const ElmContext = require('../src/elmContext')

describe("Suite Runner", () => {
  it("runs a suite of tests", (done) => {
    expectPassingScenarios('Passing', 8, [], done)
  })

  it("runs only the tagged scenarios", (done) => {
    expectPassingScenarios('Passing', 3, [ "tagged" ], done)
  })

  context("when the suite should end on the first failure", () => {
    it("stops at the first failure", (done) => {
      expectScenarios('WithFailure', { tags: [], timeout: 50, endOnFailure: true }, done, (observations) => {
        expect(observations).to.have.length(2)
        expectAccepted(observations[0])
        expectRejected(observations[1])
      })
    })
  })

  context("when the suite should report all results", () => {
    it("reports all results", (done) => {
      expectScenarios('WithFailure', { tags: [], timeout: 50, endOnFailure: false }, done, (observations) => {
        expect(observations).to.have.length(5)
        expectAccepted(observations[0])
        expectRejected(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
        expectAccepted(observations[4])
      })
    })
  })
  
  context("when the code does not compile", () => {
    it("reports zero tests", (done) => {
      expectScenarios('WithCompilationError', { tags: [], timeout: 50, endOnFailure: false }, done, (observations) => {
        expect(observations).to.have.length(0)
      })
    })
  })

  context("when the expected ports are not found", () => {
    context("when the elmSpecOut port is not found", () => {
      it("fails and reports an error", (done) => {
        expectScenarios("WithNoSendOutPort", { tags: [], timeout: 50, endOnFailure: false }, done, (observations, error) => {
          expect(observations).to.have.length(0)
          expect(error).to.deep.equal([
            reportLine("No elmSpecOut port found!"),
            reportLine("Make sure your elm-spec program uses a port defined like so", "port elmSpecOut : Message -> Cmd msg")
          ])
        })
      })
    })

    context("when the elmSpecIn port is not found", () => {
      it("fails and reports an error", (done) => {
        expectScenarios("WithNoSendInPort", { tags: [], timeout: 50, endOnFailure: false }, done, (observations, error) => {
          expect(observations).to.have.length(0)
          expect(error).to.deep.equal([
            reportLine("No elmSpecIn port found!"),
            reportLine("Make sure your elm-spec program uses a port defined like so", "port elmSpecIn : (Message -> msg) -> Sub msg")
          ])
        })
      })
    })
  })

  context("when the flags passed on init are messed up", () => {
    it("fails and reports an error", (done) => {
      expectScenariosForVersion("BAD VERSION", "Passing", { tags: [], timeout: 50, endOnFailure: false }, done, (reporter) => {
        expect(reporter.observations).to.have.length(0)
        expect(reporter.errorCount).to.equal(1)
        expect(reporter.specError).to.not.be.null
      })
    })
  })

  context("when the version is not correct", () => {
    it("fails and reports only one error", (done) => {
      expectScenariosForVersion(-1, "Passing", { tags: [], timeout: 50, endOnFailure: false }, done, (reporter) => {
        expect(reporter.observations).to.have.length(0)
        expect(reporter.errorCount).to.equal(1)
        expect(reporter.specError).to.not.be.null
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
  expectScenariosAt({
    cwd: './tests/sample',
    specPath: `./specs/${specDir}/**/*Spec.elm`
  }, options, done, (reporter) => { matcher(reporter.observations, reporter.specError) })
}

const expectScenariosForVersion = (version, specDir, options, done, matcher) => {
  expectScenariosAt({
    cwd: './tests/sample',
    specPath: `./specs/${specDir}/**/*Spec.elm`
  }, options, done, matcher, version)
}

const expectScenariosAt = (compilerOptions, options, done, matcher, version) => {
  const jsdom = new JsdomContext()
  const context = new ElmContext(jsdom.window)
  const reporter = new TestReporter()
  const runner = new SuiteRunner(context, reporter, options, version)

  const compiler = new Compiler(compilerOptions)
  jsdom.loadElm(compiler)

  runner
    .on('complete', () => {
      setTimeout(() => {
        matcher(reporter)
        done()
      }, 0)
    })
    .runAll()
}

const TestReporter = class {
  constructor() {
    this.observations = []
    this.specError = null
    this.errorCount = 0
  }

  startSuite() {
    // Nothing
  }

  record(observation) {
    this.observations.push(observation)
  }

  finish() {}

  error(err) {
    this.errorCount += 1
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
