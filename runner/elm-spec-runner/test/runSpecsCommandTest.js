const chai = require('chai')
const expect = chai.expect
const RunSpecsCommand = require("../src/runSpecsCommand")
const path = require('path')

describe("Run Specs Command", () => {
  let testReporter
  let testRunner
  let testFileWatcher
  let subject

  const compilerOptions = {
    cwd: path.join(__dirname, "./fixtures/sampleSuite"),
    specPath: "**/*Spec.elm",
    elmPath: path.join(__dirname, "../../node_modules/.bin/elm")
  }

  beforeEach(() => {
    testReporter = new TestReporter()
    testRunner = new TestRunner()
    testFileWatcher = new TestFileWatcher()
    subject = new RunSpecsCommand(testRunner, testReporter, testFileWatcher)
  })

  context("when not watching files", () => {
    
    const watchOptions = {
      globs: []
    }

    const itRunsTheSpecsOnce = () => {
      it("runs the specs", () => {
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
        const runOptions = { tags: [], endOnFailure: false }
        await subject.execute({ browserOptions, compilerOptions, runOptions, watchOptions })
      })
  
      itRunsTheSpecsOnce()
      
      it("stops the runner", () => {
        expect(testRunner.didStop).to.equal(true)
      })
    })

    context("when browser is not visible and ending on failure", () => {
      beforeEach(async () => {
        const browserOptions = { visible: false }
        const runOptions = { tags: [], endOnFailure: true }
        await subject.execute({ browserOptions, compilerOptions, runOptions, watchOptions })
      })
  
      itRunsTheSpecsOnce()
      
      it("stops the runner", () => {
        expect(testRunner.didStop).to.equal(true)
      })
    })

    context("when the browser is visible and not ending on failure", () => {
      beforeEach(async () => {
        const browserOptions = { visible: true }
        const runOptions = { tags: [], endOnFailure: false }
        await subject.execute({ browserOptions, compilerOptions, runOptions, watchOptions })
      })
  
      itRunsTheSpecsOnce()
      
      it("stops the runner", () => {
        expect(testRunner.didStop).to.equal(true)
      })
    })

    context("when the browser is visible and ending on failure", () => {
      beforeEach(async () => {
        const browserOptions = { visible: true }
        const runOptions = { tags: [], endOnFailure: true }
        await subject.execute({ browserOptions, compilerOptions, runOptions, watchOptions })
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
      
      const runOptions = { tags: [], endOnFailure: false }
      
      const watchOptions = {
        globs: [ '/some/path/src/**/*.elm', '/some/other/path/specs/**/*.elm' ]
      }

      beforeEach(async () => {
        await subject.execute({ browserOptions, compilerOptions, runOptions, watchOptions })
      })

      it("prints the globs that will be watched", async () => {
        expect(testReporter.logs[0][0].statement).to.equal("Watching Files")
        expect(testReporter.logs[0][0].detail).to.contain("/some/path/src/**/*.elm")
        expect(testReporter.logs[0][0].detail).to.contain("/some/other/path/specs/**/*.elm")
      })

      it("watches files", () => {
        expect(testFileWatcher.isWatching).to.equal(true)
      })

      it("runs the specs", () => {
        expect(testRunner.runCount).to.equal(1)
      })

      it("does not stop the runner", () => {
        expect(testRunner.didStop).to.equal(false)
      })

      context("when a file changes", () => {
        beforeEach(async () => {
          await testFileWatcher.callback("/some/path/to/a/file.elm")
        })

        it("prints the path to the file that changed", () => {
          expect(testReporter.logs[1][0].statement).to.equal("File Changed")
          expect(testReporter.logs[1][0].detail).to.equal("/some/path/to/a/file.elm")
        })

        it("runs the specs again", () => {
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
  }

  run(reporter, compilerOptions, runOptions) {
    this.runCount += 1
  }

  stop() {
    this.didStop = true
  }
}

class TestReporter {
  constructor() {
    this.logs = []
    this.didReset = false
  }

  log(message) {
    this.logs.push(message)
  }

  reset() {
    this.didReset = true
  }
}
