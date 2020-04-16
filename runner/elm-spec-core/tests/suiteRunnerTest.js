const chai = require('chai')
const expect = chai.expect
const Compiler = require('../src/compiler')
const { loadElmContext } = require('../../elm-spec-runner/src/jsdomContext')
const SuiteRunner = require('../src/suiteRunner')
const path = require('path')

describe("Suite Runner", () => {
  it("runs a suite of tests", (done) => {
    expectScenarios("Passing", { tags: [], endOnFailure: false }, done, (observations) => {
      expectAccepted(observations[0])
      expectModulePath(observations[0], "Passing/Behaviors/AnotherSpec.elm")

      expectAccepted(observations[1])
      expectModulePath(observations[1], "Passing/Behaviors/NavigationSpec.elm")

      expectAccepted(observations[2])
      expectModulePath(observations[2], "Passing/WorkerSpec.elm")

      expectAccepted(observations[3])
      expectModulePath(observations[3], "Passing/WorkerSpec.elm")

      expectAccepted(observations[4])
      expectModulePath(observations[4], "Passing/InputSpec.elm")

      expectAccepted(observations[5])
      expectModulePath(observations[5], "Passing/InputSpec.elm")

      expectAccepted(observations[6])
      expectModulePath(observations[6], "Passing/InputSpec.elm")

      expectAccepted(observations[7])
      expectModulePath(observations[7], "Passing/ClickSpec.elm")
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
        expect(observations).to.have.length(6)
        expectAccepted(observations[0])
        expectRejected(observations[1])
        expectRejected(observations[2])
        expectAccepted(observations[3])
        expectAccepted(observations[4])
        expectAccepted(observations[5])
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

  context("when a scenario logs a message", () => {
    it("sends the message to the reporter", (done) => {
      expectScenarios("WithLogs", { tags: [], endOnFailure: false }, done, (observations, error, logs) => {
        expectAccepted(observations[0])
        expect(logs).to.deep.equal([
          [ reportLine("After two clicks!") ]
        ])
      })
    })
  })

  context("when no specs are found", () => {
    it("reports an error", (done) => {
      expectScenarios('WithNoSpecs', { tags: [], endOnFailure: false }, done, (observations, error) => {
        expect(observations).to.have.length(0)
        expect(error).to.deep.equal([
          reportLine("No spec modules found!"),
          reportLine("Working directory (with elm.json)", "./tests/sample"),
          reportLine("Spec Path (relative to working directory)", "./specs/WithNoSpecs/**/*Spec.elm")
        ])
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
  }, options, done, (reporter) => { matcher(reporter.observations, reporter.specError, reporter.logs) })
}

const expectScenariosForVersion = (version, specDir, options, done, matcher) => {
  expectScenariosAt({
    cwd: './tests/sample',
    specPath: `./specs/${specDir}/**/*Spec.elm`
  }, options, done, matcher, version)
}

const expectScenariosAt = (compilerOptions, options, done, matcher, version) => {
  const compiler = new Compiler(compilerOptions)

  const context = loadElmContext(compiler)

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
    this.logs = []
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

  log(report) {
    this.logs.push(report)
  }
}

const expectAccepted = (observation) => {
  expect(observation.summary).to.equal("ACCEPT")
}

const expectRejected = (observation) => {
  expect(observation.summary).to.equal("REJECT")
}

const expectModulePath = (observation, modulePathPart) => {
  const fullPath = path.resolve(path.join("./tests/sample/specs/", modulePathPart))
  expect(observation.modulePath).to.equal(fullPath)
}

const reportLine = (statement, detail = null) => ({
  statement,
  detail
})
