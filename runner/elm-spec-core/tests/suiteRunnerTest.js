const chai = require('chai')
const expect = chai.expect
const browserify = require('browserify')
const JSDOMSpecRunner = require('../../elm-spec-runner/src/jsdomSpecRunner')
const Compiler = require('../src/compiler')
const path = require('path')

let bundledRunnerCode = ""

describe("Suite Runner", () => {
  before(async () => {
    bundledRunnerCode = await bundleRunnerCode()
  })

  it("runs the scenarios", (done) => {
    expectScenarios("Passing", { endOnFailure: false }, done, (observations) => {
      expect(observations).to.have.length(9)

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
      expectModulePath(observations[7], "Passing/FileSpec.elm")

      expectAccepted(observations[8])
      expectModulePath(observations[8], "Passing/ClickSpec.elm")
    })
  })

  context("when the runner does not support loading files", () => {
    it("presents an error when a scenario attempts to load a file", (done) => {
      expectSpecWithNoBrowserCapabilities('./specs/Passing/FileSpec.elm', { endOnFailure: false }, done, (observations) => {
        expect(observations[0].summary).to.equal("REJECT")
        expect(observations[0].report).to.deep.equal([
          reportLine("Scenario attempted to load a file from disk, but this runner does not support that capability."),
          reportLine("If you need to load a file from disk, consider using the standard elm-spec runner.")
        ])
      })
    })
  })

  context("when the suite should end on the first failure", () => {
    it("stops at the first failure", (done) => {
      expectScenarios('WithFailure', { endOnFailure: true }, done, (observations) => {
        expect(observations).to.have.length(2)
        expectAccepted(observations[0])
        expectRejected(observations[1])
      })
    })
  })

  context("when some scenarios are picked", () => {
    it("runs only the picked scenarios and skips the others", (done) => {
      expectScenarios("WithPicked", { endOnFailure: false }, done, (observations) => {
        expectSkipped(observations[0])

        expectAccepted(observations[1])
        expect(observations[1].description).to.equal("It renders the count [PICKED]")

        expectSkipped(observations[2])

        expectAccepted(observations[3])
        expect(observations[3].description).to.equal("It renders the text on the view [PICKED]")

        expectSkipped(observations[4])
        expectSkipped(observations[5])
      })
    })
  })

  context("when some scenarios are skipped", () => {
    it("does not executed the skipped scenarios", (done) => {
      expectScenarios("WithSkipped", { endOnFailure: false }, done, (observations) => {
        expect(observations).to.have.length(6)

        expectSkipped(observations[0])

        expectAccepted(observations[1])
        expect(observations[1].description).to.equal("It renders the count [NOT SKIPPED]")

        expectAccepted(observations[2])
        expect(observations[2].description).to.equal("It shows a different page [NOT SKIPPED]")

        expectAccepted(observations[3])
        expect(observations[3].description).to.equal("It renders the text on the view [NOT SKIPPED]")

        expectSkipped(observations[4])
        expectSkipped(observations[5])
      })
    })
  })

  context("when the suite should report all results", () => {
    it("reports all results", (done) => {
      expectScenarios('WithFailure', { endOnFailure: false }, done, (observations) => {
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
      expectScenarios('WithMultiVisibilityChange', { endOnFailure: false }, done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
      })
    })
    it("resets resize events as expected", (done) => {
      expectScenarios("WithMultiResize", { endOnFailure: false }, done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
      })
    })
    it("resets arbitrary document events as expected", (done) => {
      expectScenarios("WithMultiDocumentClick", { endOnFailure: false }, done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
      })
    })
  })

  context("when a scenario logs a message", () => {
    it("sends the message to the reporter", (done) => {
      expectScenarios("WithLogs", { endOnFailure: false }, done, (observations, error, logs) => {
        expectAccepted(observations[0])
        expect(logs).to.deep.equal([
          [ reportLine("After two clicks!") ]
        ])
      })
    })
  })

  context("when no specs are found", () => {
    it("reports an error", (done) => {
      expectScenarios('WithNoSpecs', { endOnFailure: false }, done, (observations, error) => {
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
      expectScenarios('WithCompilationError', { endOnFailure: false }, done, (observations, error) => {
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
        expectScenarios("WithNoSendOutPort", { endOnFailure: false }, done, (observations, error) => {
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
        expectScenarios("WithNoSendInPort", { endOnFailure: false }, done, (observations, error) => {
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
      expectScenariosForVersion("BAD VERSION", "Passing", { endOnFailure: false }, done, (reporter) => {
        expect(reporter.observations).to.have.length(0)
        expect(reporter.errorCount).to.equal(1)
        expect(reporter.specError).to.not.be.null
      })
    })
  })

  context("when the version is not correct", () => {
    it("fails and reports only one error", (done) => {
      expectScenariosForVersion(-1, "Passing", { endOnFailure: false }, done, (reporter) => {
        expect(reporter.observations).to.have.length(0)
        expect(reporter.errorCount).to.equal(1)
        expect(reporter.specError).to.not.be.null
      })
    })
  })

})

const expectSpecWithNoBrowserCapabilities = (specPath, options, done, matcher) => {
  expectScenariosAt({
    cwd: './tests/sample',
    specPath: specPath,
    logLevel: Compiler.LOG_LEVEL.SILENT
  }, options, done, (reporter) => { matcher(reporter.observations, reporter.specError, reporter.logs) }, undefined,
  (window) => {
    delete window["_elm_spec_read_file"]
  })
}

const expectScenarios = (specDir, options, done, matcher) => {
  expectScenariosAt({
    cwd: './tests/sample',
    specPath: `./specs/${specDir}/**/*Spec.elm`,
    logLevel: Compiler.LOG_LEVEL.SILENT
  }, options, done, (reporter) => { matcher(reporter.observations, reporter.specError, reporter.logs) })
}

const expectScenariosForVersion = (version, specDir, options, done, matcher) => {
  expectScenariosAt({
    cwd: './tests/sample',
    specPath: `./specs/${specDir}/**/*Spec.elm`,
    logLevel: Compiler.LOG_LEVEL.SILENT
  }, options, done, matcher, version)
}

const expectScenariosAt = (compilerOptions, options, done, matcher, version, transformer) => {
  const runner = new JSDOMSpecRunner()
  const dom = runner.getDom(compilerOptions.cwd)

  if (transformer) {
    transformer(dom.window)
  }

  dom.window.eval(bundledRunnerCode)
  
  const compiler = new Compiler(compilerOptions)
  const compiledCode = compiler.compile()
  dom.window.eval(compiledCode)

  dom.window._elm_spec.run(options, version)
    .then((reporter) => {
      setTimeout(() => {
        matcher(reporter)
        done()
      }, 0)
    })
}

const bundleRunnerCode = () => {
  const b = browserify();
  b.add(path.join(__dirname, "helpers", "specRunner.js"));
  
  return new Promise((resolve, reject) => {  
    let bundle = ''
    const stream = b.bundle()
    stream.on('data', function(data) {
      bundle += data.toString()
    })
    stream.on('end', function() {
      resolve(bundle)
    })
  })
}

const expectAccepted = (observation) => {
  expect(observation.summary).to.equal("ACCEPT")
}

const expectRejected = (observation) => {
  expect(observation.summary).to.equal("REJECT")
}

const expectSkipped = (observation) => {
  expect(observation.summary).to.equal("SKIPPED")
}

const expectModulePath = (observation, modulePathPart) => {
  const fullPath = path.resolve(path.join("./tests/sample/specs/", modulePathPart))
  expect(observation.modulePath).to.equal(fullPath)
}

const reportLine = (statement, detail = null) => ({
  statement,
  detail
})
