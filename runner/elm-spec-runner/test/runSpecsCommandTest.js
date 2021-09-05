const chai = require('chai')
chai.use(require('chai-things'));
const expect = chai.expect
const RunSpecsCommand = require("../src/runSpecsCommand")
const { SuiteRunner } = require("elm-spec-core")
const Compiler = require('elm-spec-core/compiler')

describe("Run Specs Command", () => {
  let testReporter, testRunner, testFileWatcher, testCompiler, subject, executionResult

  beforeEach(() => {
    testReporter = new TestReporter()
    testRunner = new TestRunner()
    testFileWatcher = new TestFileWatcher()
    testCompiler = new TestCompiler("compiled-code")

    subject = new RunSpecsCommand(testCompiler, testRunner, testReporter, testFileWatcher)
  })

  context("when not watching files", () => {
    
    const watchOptions = {
      globs: []
    }

    const itRunsTheSpecsOnce = () => {
      it("compiles and runs the specs", () => {
        expect(testCompiler.compileCount).to.equal(1)
        expect(testRunner.compiledCode).to.equal("compiled-code")
        expect(testRunner.runCount).to.equal(1)
      })
  
      it("does not watch the files", () => {
        expect(testFileWatcher.isWatching).to.equal(false)
      })
  
      it("does not print any logs", () => {
        expect(testReporter.logs).to.deep.equal([])
      })
    }

    context("when the spec run completes normally", () => {
      context("when there is only one segment", () => {
        beforeEach(async () => {
          const browserOptions = { visible: false }
          const runOptions = { endOnFailure: false }
          testRunner.result = [ { status: SuiteRunner.STATUS.OK, accepted: 1, rejected: 0, skipped: 0 } ]
          executionResult = await subject.execute({ browserOptions, runOptions, watchOptions })
        })

        it("returns the summarized status", () => {
          expect(executionResult).to.deep.equal({ status: SuiteRunner.STATUS.OK, accepted: 1, rejected: 0, skipped: 0 })
        })
      })

      context("when there are multiple segments", () => {
        beforeEach(async () => {
          const browserOptions = { visible: false }
          const runOptions = { parallelSegments: 3, endOnFailure: false }
          testRunner.result = [
            { status: SuiteRunner.STATUS.OK, accepted: 1, rejected: 0, skipped: 3 },
            { status: SuiteRunner.STATUS.OK, accepted: 2, rejected: 1, skipped: 0 },
            { status: SuiteRunner.STATUS.OK, accepted: 1, rejected: 2, skipped: 1 }
          ]
          executionResult = await subject.execute({ browserOptions, runOptions, watchOptions })
        })

        it("returns the summarized status", () => {
          expect(executionResult).to.deep.equal({ status: "Ok", accepted: 4, rejected: 3, skipped: 4 })
        })
      })
    })

    context("when there is an error running the specs", () => {
      beforeEach(async () => {
        const browserOptions = { visible: false }
        const runOptions = { parallelSegments: 3, endOnFailure: false }
        testRunner.result = [
          { status: SuiteRunner.STATUS.OK, accepted: 1, rejected: 0, skipped: 3 },
          { status: SuiteRunner.STATUS.ERROR },
          { status: SuiteRunner.STATUS.OK, accepted: 1, rejected: 2, skipped: 1 }
        ]
        executionResult = await subject.execute({ browserOptions, runOptions, watchOptions })
      })

      it("returns the summarized status", () => {
        expect(executionResult).to.deep.equal({ status: SuiteRunner.STATUS.ERROR })
      })
    })

    context("when browser is not visible and not ending on failure", () => {
      beforeEach(async () => {
        const browserOptions = { visible: false }
        const runOptions = { endOnFailure: false }
        await subject.execute({ browserOptions, runOptions, watchOptions })
      })
  
      itRunsTheSpecsOnce()
      
      it("stops the runner", () => {
        expect(testRunner.didStop).to.equal(true)
      })
    })

    context("when browser is not visible and ending on failure", () => {
      beforeEach(async () => {
        const browserOptions = { visible: false }
        const runOptions = { endOnFailure: true }
        await subject.execute({ browserOptions, runOptions, watchOptions })
      })
  
      itRunsTheSpecsOnce()
      
      it("stops the runner", () => {
        expect(testRunner.didStop).to.equal(true)
      })
    })

    context("when the browser is visible and not ending on failure", () => {
      beforeEach(async () => {
        const browserOptions = { visible: true }
        const runOptions = { endOnFailure: false }
        await subject.execute({ browserOptions, runOptions, watchOptions })
      })
  
      itRunsTheSpecsOnce()
      
      it("stops the runner", () => {
        expect(testRunner.didStop).to.equal(true)
      })
    })

    context("when the browser is visible and ending on failure", () => {
      beforeEach(async () => {
        const browserOptions = { visible: true }
        const runOptions = { endOnFailure: true }
        await subject.execute({ browserOptions, runOptions, watchOptions })
      })
  
      itRunsTheSpecsOnce()
  
      it("does not stop the runner", () => {
        expect(testRunner.didStop).to.equal(false)
      })
    })
  })

  context("when watching files", () => {
    context("when directories are found to watch", () => {
      const browserOptions = { visible: false }
      
      const runOptions = { endOnFailure: false }
      
      const watchOptions = {
        globs: [ '/some/path/src/**/*.elm', '/some/other/path/specs/**/*.elm' ]
      }

      let executionResult

      beforeEach(async () => {
        executionResult = await subject.execute({ browserOptions, runOptions, watchOptions })
      })

      it("returns that it is watching", () => {
        expect(executionResult).to.deep.equal({ status: "Watching" })
      })

      it("prints the globs that will be watched", async () => {
        expect(testReporter.logs).to.contain("Watching Files")
        expect(testReporter.logs).to.include.something.that.satisfies(x => x.includes("/some/path/src/**/*.elm"))
        expect(testReporter.logs).to.include.something.that.satisfies(x => x.includes("/some/other/path/specs/**/*.elm"))
      })

      it("watches files", () => {
        expect(testFileWatcher.isWatching).to.equal(true)
      })

      it("compiles and runs the specs", () => {
        expect(testCompiler.compileCount).to.equal(1)
        expect(testRunner.compiledCode).to.equal("compiled-code")
        expect(testRunner.runCount).to.equal(1)
      })

      it("does not stop the runner", () => {
        expect(testRunner.didStop).to.equal(false)
      })

      context("when a file changes", () => {
        beforeEach(async () => {
          testCompiler.code = "newly-compiled-code"
          await testFileWatcher.callback("/some/path/to/a/file.elm")
        })

        it("prints the path to the file that changed", () => {
          expect(testReporter.logs).to.contain("File changed: /some/path/to/a/file.elm")
        })

        it("compiles and runs the specs again", () => {
          expect(testCompiler.compileCount).to.equal(2)
          expect(testRunner.compiledCode).to.equal("newly-compiled-code")
          expect(testRunner.runCount).to.equal(2)
        })

        it("resets the reporter", () => {
          expect(testReporter.didReset).to.equal(true)
        })

        it("does not stop the runner", () => {
          expect(testRunner.didStop).to.equal(false)
        })  
      })
    })
  })

  context("when compilation fails", () => {
    beforeEach(async () => {
      testCompiler.compilerStatus = Compiler.STATUS.COMPILATION_FAILED
      const browserOptions = { visible: false }
      const runOptions = { endOnFailure: false }
      const watchOptions = {
        globs: []
      }
      await subject.execute({ browserOptions, runOptions, watchOptions })
    })

    it("alerts the reporter", () => {
      expect(testReporter.actionPerformed).to.equal(false)
    })
  })

  context("when compilation succeeds", () => {
    beforeEach(async () => {
      testCompiler.compilerStatus = Compiler.STATUS.COMPILATION_SUCCEEDED
      const browserOptions = { visible: false }
      const runOptions = { endOnFailure: false }
      const watchOptions = {
        globs: []
      }
      await subject.execute({ browserOptions, runOptions, watchOptions })
    })

    it("alerts the reporter", () => {
      expect(testReporter.actionPerformed).to.equal(true)
    })
  })

})

class TestFileWatcher {
  constructor() {
    this.isWatching = false
  }

  watch(files, callback) {
    this.isWatching = true
    this.callback = callback
  }
}

class TestRunner {
  result = [ { status: SuiteRunner.STATUS.OK, accepted: 1, rejected: 0, skipped: 0 } ]

  start(browserOptions) {
    this.runCount = 0
    this.didStop = false
    this.compiledCode = ""
  }

  run(runOptions, compiledCode, reporter) {
    this.runCount += 1
    this.compiledCode = compiledCode

    return Promise.resolve(this.result)
  }

  stop() {
    this.didStop = true
  }
}

class TestCompiler {
  constructor(code) {
    this.code = code
    this.compileCount = 0
    this.compilerStatus = Compiler.STATUS.COMPILATION_SUCCEEDED
  }

  compile() {
    this.compileCount += 1
    return this.code
  }

  status() {
    return this.compilerStatus
  }
}

class TestReporter {
  constructor() {
    this.logs = []
    this.didReset = false
    this.actionPerformed = false
  }

  async performAction(startMessage, finishMessage, action) {
    const result = await action()
    this.actionPerformed = result.isOk
    return result.value
  }

  printLine(line) {
    this.logs.push(line)
  }

  log(message) {}

  reset() {
    this.didReset = true
  }
}
