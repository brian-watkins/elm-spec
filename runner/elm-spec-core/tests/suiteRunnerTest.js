const chai = require('chai')
const expect = chai.expect
const Compiler = require('../src/compiler')
const glob = require('glob')
const { loadElmContext } = require('../../elm-spec-runner/src/jsdomContext')
const SuiteRunner = require('../src/suiteRunner')

describe("Suite Runner", () => {
  it("runs a suite of tests", (done) => {
    expectScenarios("Passing", { tags: [], endOnFailure: false }, done, (observation) => {
      expectAccepted(observation[0])
      expect(observation[0].modulePath).to.deep.equal(["Passing", "Behaviors", "AnotherSpec"])

      expectAccepted(observation[1])
      expect(observation[1].modulePath).to.deep.equal(["Passing", "Behaviors", "NavigationSpec"])

      expectAccepted(observation[2])
      expect(observation[2].modulePath).to.deep.equal(["Passing", "WorkerSpec"])

      expectAccepted(observation[3])
      expect(observation[3].modulePath).to.deep.equal(["Passing", "WorkerSpec"])

      expectAccepted(observation[4])
      expect(observation[4].modulePath).to.deep.equal(["Passing", "InputSpec"])

      expectAccepted(observation[5])
      expect(observation[5].modulePath).to.deep.equal(["Passing", "InputSpec"])

      expectAccepted(observation[6])
      expect(observation[6].modulePath).to.deep.equal(["Passing", "InputSpec"])

      expectAccepted(observation[7])
      expect(observation[7].modulePath).to.deep.equal(["Passing", "ClickSpec"])
    })
  })

  it("runs only the tagged scenarios", (done) => {
    expectPassingScenarios('Passing', 3, [ "tagged" ], done)
  })

  context("when the suite should end on the first failure", () => {
    it("stops at the first failure", (done) => {
      expectScenarios('WithFailure', { tags: [], endOnFailure: true }, done, (observations) => {
        expect(observations).to.have.length(2)
        expectAccepted(observations[0])
        expectRejected(observations[1])
      })
    })
  })

  context("when some scenarios are picked", () => {
    context("when no tags are supplied", () => {
      it("runs only the picked scenarios", (done) => {
        expectScenarios("WithPicked", { tags: [], endOnFailure: false }, done, (observations) => {
          expect(observations).to.have.length(2)

          expectAccepted(observations[0])
          expect(observations[0].description).to.equal("It renders the count [PICKED]")

          expectAccepted(observations[1])
          expect(observations[1].description).to.equal("It renders the text on the view [PICKED]")
        })
      })
    })
    context("when some tags are supplied", (done) => {
      it("runs the picked scenarios", (done) => {
        expectScenarios("WithPicked", { tags: [ "tagged" ], endOnFailure: false }, done, (observations) => {
          expect(observations).to.have.length(2)

          expectAccepted(observations[0])
          expect(observations[0].description).to.equal("It renders the count [PICKED]")

          expectAccepted(observations[1])
          expect(observations[1].description).to.equal("It renders the text on the view [PICKED]")
        })
      })
    })
  })

  context("when the suite should report all results", () => {
    it("reports all results", (done) => {
      expectScenarios('WithFailure', { tags: [], endOnFailure: false }, done, (observations) => {
        expect(observations).to.have.length(5)
        expectAccepted(observations[0])
        expectRejected(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
        expectAccepted(observations[4])
      })
    })
  })
  
  context("when the suite has multiple programs with global event listeners", () => {
    it("resets visibility change events as expected", (done) => {
      expectScenarios('WithMultiVisibilityChange', { tags: [], endOnFailure: false }, done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
      })
    })
    it("resets resize events as expected", (done) => {
      expectScenarios("WithMultiResize", { tags: [], endOnFailure: false }, done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
      })
    })
    it("resets arbitrary document events as expected", (done) => {
      expectScenarios("WithMultiDocumentClick", { tags: [], endOnFailure: false }, done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
      })
    })
  })

  context("when the code does not compile", () => {
    it("reports zero tests", (done) => {
      expectScenarios('WithCompilationError', { tags: [], endOnFailure: false }, done, (observations, error) => {
        expect(observations).to.have.length(0)
        expect(error).to.deep.equal([
          reportLine("Unable to compile the elm-spec program!")
        ])
      })
    })
  })

  context("when the expected ports are not found", () => {
    context("when the elmSpecOut port is not found", () => {
      it("fails and reports an error", (done) => {
        expectScenarios("WithNoSendOutPort", { tags: [], endOnFailure: false }, done, (observations, error) => {
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
        expectScenarios("WithNoSendInPort", { tags: [], endOnFailure: false }, done, (observations, error) => {
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
      expectScenariosForVersion("BAD VERSION", "Passing", { tags: [], endOnFailure: false }, done, (reporter) => {
        expect(reporter.observations).to.have.length(0)
        expect(reporter.errorCount).to.equal(1)
        expect(reporter.specError).to.not.be.null
      })
    })
  })

  context("when the version is not correct", () => {
    it("fails and reports only one error", (done) => {
      expectScenariosForVersion(-1, "Passing", { tags: [], endOnFailure: false }, done, (reporter) => {
        expect(reporter.observations).to.have.length(0)
        expect(reporter.errorCount).to.equal(1)
        expect(reporter.specError).to.not.be.null
      })
    })
  })

})

const expectPassingScenarios = (specDir, number, tags, done) => {
  expectScenarios(specDir, { tags: tags, endOnFailure: false }, done, (observations) => {
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
  const compiler = new Compiler(compilerOptions)
  const specFiles = glob.sync(compilerOptions.specPath, { cwd: compilerOptions.cwd })

  const context = loadElmContext(compiler)(specFiles)

  const reporter = new TestReporter()
  const runner = new SuiteRunner(context, reporter, options, version)

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
