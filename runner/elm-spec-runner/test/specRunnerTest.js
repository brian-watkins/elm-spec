const chai = require('chai')
const expect = chai.expect
const JSDOMSpecRunner = require('../src/jsdomSpecRunner')
const BrowserSpecSunner = require('../src/browserSpecRunner')
const RobotRunner = require("./helpers/robotRunner")
const FileLoader = require('../src/fileLoader')
const { SuiteRunner } = require('elm-spec-core')
const Compiler = require('elm-spec-core/compiler')
const RemoteSpecRunner = require('../src/remoteSpecRunner')

const expectBehaviorFor = (browserName, runner, runnerProperties) => {
  describe(browserName, () => {
    let testRun

    afterEach(() => {
      runner.stop()
    })

    context(`when there is an error running the specs in ${browserName}`, () => {
      beforeEach(async () => {
        testRun = await runForTest(runner, errorSpecs)
      })
      
      it("reports the error", () => {
        expect(testRun.testReporter.errorCount).to.equal(1)
        expect(testRun.results).to.deep.equal([ { status: SuiteRunner.STATUS.ERROR }])
      })
    })

    context(`when all the observations are accepted in ${browserName}`, () => {
      beforeEach(async () => {
        testRun = await runForTest(runner, allSpecs)
      })
 
      it("calls start and finish", () => {
        expect(testRun.testReporter.startCount).to.equal(1)
        expect(testRun.testReporter.finishCount).to.equal(1)
      })

      it("reports all accepted", () => {
        expect(testRun.testReporter.accepted).to.equal(10)
        expect(testRun.results).to.deep.equal([ okResult(10, 0, 0) ])
      })

      context(`when the specs are executed again in ${browserName}, like in watch mode`, () => {
        let testReporter, results

        beforeEach(async () => {
          testReporter = new TestReporter()
          results = await runner.run(testRunnerOptions, compileCodeForTests(allSpecs), testReporter)
        })

        it("reports all are still accepted", () => {
          expect(testReporter.accepted).to.equal(10)
          expect(results).to.deep.equal([ okResult(10, 0, 0) ])
        })
      })
    })

    context(`when the scenarios are executed in parallel in ${browserName}`, () => {
      beforeEach(async () => {
        testRun = await runForTest(runner, passingAndFailingSpecs, { ...testRunnerOptions, parallelSegments: 3 })
      })

      it("reports the correct number of accepted, skipped, and rejected scenarios", () => {
        expect(testRun.testReporter.accepted).to.equal(4)
        expect(testRun.testReporter.rejected).to.equal(2)
        expect(testRun.testReporter.skipped).to.equal(1)
      })

      if (runnerProperties.supportsParallel) {
        it("calls start and finish for each segment", () => {
          expect(testRun.testReporter.startCount).to.equal(3)
          expect(testRun.testReporter.finishCount).to.equal(3)
        })
  
        it("provides results for each segment", () => {
          expect(testRun.results).to.deep.equal([
            okResult(2, 2, 1),
            okResult(2, 0, 0),
            okResult(0, 0, 0)
          ])
        })
      }
    })

    context(`when the spec emits log messages in ${browserName}`, () => {
      beforeEach(async () => {
        testRun = await runForTest(runner, specsWithLogs)
      })

      it("reports the log message", () => {
        expect(testRun.testReporter.logs.length).to.equal(1)
      })
    })

    context(`when scenarios are skipped in ${browserName}`, () => {
      beforeEach(async () => {
        testRun = await runForTest(runner, skippedSpecs)
      })

      it(`reports the correct number of skipped observations in ${browserName}`, () => {
        expect(testRun.testReporter.skipped).to.equal(3)
        expect(testRun.results).to.deep.equal([ okResult(3, 0, 3) ])
      })
    })

    context(`when observations are rejected in ${browserName}`, () => {
      beforeEach(async () => {
        testRun = await runForTest(runner, failingSpec)
      })

      it(`reports the correct number of rejections in ${browserName}`, () => {
        expect(testRun.testReporter.rejected).to.equal(2)
        expect(testRun.results).to.deep.equal([ okResult(0, 2, 0) ])
      })
    })

    context(`when end on first failure in ${browserName}`, () => {
      beforeEach(async () => {
        testRun = await runForTest(runner, failingSpec, { ...testRunnerOptions, endOnFailure: true })
      })

      it(`reports only the first failure in ${browserName}`, () => {
        expect(testRun.testReporter.rejected).to.equal(1)
        expect(testRun.results).to.deep.equal([ okResult(0, 1, 0) ])
      })
    })
  })
}

const runForTest = async (runner, compilerOptions, runnerOptions = testRunnerOptions) => {
  const testReporter = new TestReporter()
  await runner.start(testBrowserOptions)
  const results = await runner.run(runnerOptions, compileCodeForTests(compilerOptions), testReporter)
  return { results, testReporter }
}

const compileCodeForTests = (compilerOptions) => {
  const compiler = new Compiler(compilerOptions)
  return compiler.compile()
}

describe("Spec Runners", async () => {
  const fileLoader = new FileLoader("../elm-spec-core/tests/sample/")
  expectBehaviorFor('JSDOM', new JSDOMSpecRunner(fileLoader), { supportsParallel: true })
  expectBehaviorFor('Chromium', new BrowserSpecSunner('chromium', fileLoader), { supportsParallel: true })
  expectBehaviorFor('Remote Browser', new RobotRunner(new RemoteSpecRunner(fileLoader)), { supportsParallel: false })
})

const testBrowserOptions = {
  visible: false,
  cssFiles: []
}

const testRunnerOptions = {
  endOnFailure: false,
  parallelSegments: 1
}

const passingAndFailingSpecs = {
  cwd: "../elm-spec-core/tests/sample/",
  specPath: "./specs/WithFailure/**/*Spec.elm",
  elmPath: "../../node_modules/.bin/elm",
  logLevel: Compiler.LOG_LEVEL.SILENT
}

const failingSpec = {
  cwd: "../elm-spec-core/tests/sample/",
  specPath: "./specs/WithFailure/MoreSpec.elm",
  elmPath: "../../node_modules/.bin/elm",
  logLevel: Compiler.LOG_LEVEL.SILENT
}

const skippedSpecs = {
  cwd: "../elm-spec-core/tests/sample/",
  specPath: "./specs/WithSkipped/**/*Spec.elm",
  elmPath: "../../node_modules/.bin/elm",
  logLevel: Compiler.LOG_LEVEL.SILENT
}

const allSpecs = {
  cwd: "../elm-spec-core/tests/sample/",
  specPath: "./specs/Passing/**/*Spec.elm",
  elmPath: "../../node_modules/.bin/elm",
  logLevel: Compiler.LOG_LEVEL.QUIET
}

const errorSpecs = {
  cwd: "../elm-spec-core/tests/sample/",
  specPath: "./specs/WithNoSendInPort/**/*Spec.elm",
  elmPath: "../../node_modules/.bin/elm",
  logLevel: Compiler.LOG_LEVEL.SILENT
}

const specsWithLogs = {
  cwd: "../elm-spec-core/tests/sample/",
  specPath: "./specs/WithLogs/**/*Spec.elm",
  elmPath: "../../node_modules/.bin/elm",
  logLevel: Compiler.LOG_LEVEL.SILENT
}

const okResult = (accepted, rejected, skipped) => {
  return { status: SuiteRunner.STATUS.OK, accepted, rejected, skipped }
}

const TestReporter = class {
  constructor() {
    this.observations = []
    this.logs = []
    this.errorCount = 0
    this.startCount = 0
    this.finishCount = 0
  }

  info() {}

  startSuite() {
    this.startCount += 1
  }

  record(observation) {
    this.observations.push(observation)
  }

  get accepted() {
    return this.observations.filter(o => o.summary === "ACCEPTED").length
  }

  get rejected() {
    return this.observations.filter(o => o.summary === "REJECTED").length
  }

  get skipped() {
    return this.observations.filter(o => o.summary === "SKIPPED").length
  }

  finish() {
    this.finishCount += 1
  }

  error(err) {
    this.errorCount += 1
  }

  log(report) {
    this.logs.push(report)
  }
}
