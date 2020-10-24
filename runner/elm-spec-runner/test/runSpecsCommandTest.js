const chai = require('chai')
chai.use(require('chai-things'));
const expect = chai.expect
const RunSpecsCommand = require("../src/runSpecsCommand")

describe("Run Specs Command", () => {
  let testReporter
  let testRunner
  let testFileWatcher
  let testCompiler
  let subject

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

      beforeEach(async () => {
        await subject.execute({ browserOptions, runOptions, watchOptions })
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
  start(browserOptions) {
    this.runCount = 0
    this.didStop = false
    this.compiledCode = ""
  }

  run(runOptions, compiledCode, reporter) {
    this.runCount += 1
    this.compiledCode = compiledCode
  }

  stop() {
    this.didStop = true
  }
}

class TestCompiler {
  constructor(code) {
    this.code = code
    this.compileCount = 0
  }

  compile() {
    this.compileCount += 1
    return this.code
  }
}

class TestReporter {
  constructor() {
    this.logs = []
    this.didReset = false
  }

  performAction(startMessage, finishMessage, action) {
    return action()
  }

  printLine(line) {
    this.logs.push(line)
  }

  log(message) {}

  reset() {
    this.didReset = true
  }
}
