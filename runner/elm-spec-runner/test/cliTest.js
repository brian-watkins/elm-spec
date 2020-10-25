const shell = require('shelljs')
const chai = require('chai')
chai.use(require('chai-string'))
const expect = chai.expect

describe('elm-spec-runner', () => {
  context("when the spec runs", () => {
    it("executes the spec and prints the number accepted", () => {
      const command = "./bin/run" +
        " --elm ../../node_modules/.bin/elm" +
        " --specRoot ../elm-spec-core/tests/sample/" +
        " --specs ./specs/Passing/**/*Spec.elm"
      const runnerOutput = shell.exec(command, { silent: true })
      expect(runnerOutput.stdout).to.contain("Compiling Elm ... Done")
      expect(runnerOutput.stdout).to.contain("Accepted: 10")
    })

    context("in parallel", () => {
      it("executes all the scenarios and prints the number accepted", () => {
        const command = "./bin/run" +
          " --elm ../../node_modules/.bin/elm" +
          " --specRoot ../elm-spec-core/tests/sample/" +
          " --specs ./specs/Passing/**/*Spec.elm" +
          " --parallel"
        const runnerOutput = shell.exec(command, { silent: true })
        expect(runnerOutput.stdout).to.contain("Accepted: 10")
      })
    })
  })

  context("when files are watched", () => {
    it("executes the spec once and on each change, and it ignores changes while running", async () => {
      const command = "./bin/run" +
        " --elm ../../node_modules/.bin/elm" +
        " --specRoot ../elm-spec-core/tests/sample/" +
        " --specs ./specs/Passing/**/*Spec.elm" +
        " --watch"
      
      const runnerOutput = await new Promise((resolve, reject) => {
        const runner = shell.exec(command, { async: true, silent: true }, (code, stdout, stderr) => {
          resolve(stdout)
        })
  
        setTimeout(() => {
          shell.touch("../elm-spec-core/tests/sample/specs/Passing/ClickSpec.elm")
          shell.touch("../elm-spec-core/tests/sample/specs/Passing/ClickSpec.elm")
          setTimeout(() => {
            runner.kill()
          }, 2000)
        }, 2000)
      })

      expect(runnerOutput).to.contain("Watching Files")
      expect(runnerOutput).to.contain("../elm-spec-core/tests/sample/src/**/*.elm")
      expect(runnerOutput).to.contain("../elm-spec-core/tests/sample/specs/**/*.elm")
      expect(runnerOutput).to.contain("File changed: ../elm-spec-core/tests/sample/specs/Passing/ClickSpec.elm")
      expect(runnerOutput).to.have.entriesCount("Accepted: 10", 2)
    })
  })

  context("when the specified elm executable does not exist", () => {
    it("prints an error", () => {
      const command = "./bin/run --elm blah"
      const runnerOutput = shell.exec(command, { silent: true })
      expect(runnerOutput.stderr).to.contain("No elm executable found at: blah")
    })
  })

  context("when the specs elm.json cannot be found", () => {
    it("prints an error", () => {
      const command = "./bin/run" +
        " --elm ../../node_modules/.bin/elm" +
        " --specRoot ../elm-spec-core/tests/"
      const runnerOutput = shell.exec(command, { silent: true })
      expect(runnerOutput.stderr).to.contain("Expected an elm.json at: ../elm-spec-core/tests/elm.json")
    })
  })

})