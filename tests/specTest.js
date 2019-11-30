const chai = require('chai')
const expect = chai.expect
const {
  expectPassingSpec,
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine,
  runInContext
} = require('./helpers/SpecHelpers')

describe("spec", () => {
  describe("when there are no scenarios", () => {
    it("returns no observations", (done) => {
      expectSpec("SpecSpec", "noScenarios", done, (observations) => {
        expect(observations).to.have.length(0)
      })
    })
  })

  describe("when there are multiple when blocks", () => {
    it("processes the steps as expected", (done) => {
      expectPassingSpec("SpecSpec", "multipleWhen", done)
    })

    it("sends all the conditions", (done) => {
      expectPassingSpec("SpecSpec", "multipleWhen", done, (observations) => {
        expect(observations[0].conditions).to.deep.equal([
          "A Spec",
          "Scenario: multiple when blocks",
          "When the first two subs are sent",
          "When a third sub is sent"
        ])
      })
    })
  })

  describe("when there are multiple scenarios", () => {
    it("executes the observations in each scenario", (done) => {
      expectSpec("SpecSpec", "scenarios", done, (observations) => {
        expect(observations).to.have.length(3)
        
        expectObservation(observations[0], "ACCEPT", "It records the number",
          [ "Multiple scenarios",
            "Scenario: the happy path",
            "When a single message is sent"
          ]
        )

        expectObservation(observations[1], "ACCEPT", "It records the numbers",
          [ "Multiple scenarios",
            "Scenario: multiple sub messages are sent",
            "When multiple messages are sent"
          ]
        )

        expectObservation(observations[2], "ACCEPT", "It records the number",
          [ "Multiple scenarios",
            "Scenario: a different message is sent",
            "When a single message is sent"
          ]
        )
      })
    })
  })

  context("when the spec suite does not end on first failure", () => {
    context("when there is a timeout in a step", () => {
      it("fails the scenario but continues to execute other scenarios", (done) => {
        expectSpec("SpecSpec", "timeout", done, (observations) => {
          expect(observations).to.have.length(2)
          expectRejected(observations[0], [
            reportLine("Scenario timeout of 20ms exceeded!")
          ])
          expectAccepted(observations[1])
        }, { timeout: 20, endOnFailure: false })
      })
      context("when the timeout is the final failure", () => {
        it("leaves the html program in a mostly usable state", (done) => {
          expectSpec("HtmlSpec", "timeout", () => {
            checkThatProgramFunctions(done)
          }, () => {}, { timeout: 20, endOnFailure: false })
        })  
      })
    })
    context("when an observation fails", (done) => {
      it("fails the scenario but contines to execute other scenarios", (done) => {
        expectSpec("HtmlSpec", "failing", done, (observations) => {
          expect(observations).to.have.length(2)
          expect(observations[0].summary).to.equal("REJECT")
          expectAccepted(observations[1])
        })
      })
      it("leaves the html program in a mostly usable state", (done) => {
        expectSpec("HtmlSpec", "failing", () => {
          checkThatProgramFunctions(done)
        }, () => {})
      })
    })
  })

  context("when the spec ends on failure", () => {
    context("because a step times out", () => {
      it("finishes the spec suite run after the failure", (done) => {
        expectSpec("SpecSpec", "timeout", done, (observations) => {
          expect(observations).to.have.length(1)
          expectRejected(observations[0], [
            reportLine("Scenario timeout of 20ms exceeded!")
          ])
        }, { timeout: 20, endOnFailure: true })
      })
      it("leaves the html program in a mostly usable state", (done) => {
        expectSpec("HtmlSpec", "timeout", () => {
          checkThatProgramFunctions(done)
        }, () => {}, { timeout: 20, endOnFailure: true })
      })
    })
    context("because an observation fails", () => {
      it("finishes the spec suite run after the failure", (done) => {
        expectSpec("HtmlSpec", "failing", done, (observations) => {
          expect(observations).to.have.length(1)
          expect(observations[0].summary).to.equal("REJECT")
        }, { timeout: 20, endOnFailure: true })
      })
      it("leaves the html program in a mostly usable state", (done) => {
        expectSpec("HtmlSpec", "failing", () => {
          checkThatProgramFunctions(done)
        }, () => {}, { timeout: 20, endOnFailure: true })
      })
    })
  })
})

const checkThatProgramFunctions = (done) => {
  runInContext(async (window) => {
    const wait = () => new Promise((resolve) => setTimeout(resolve, 0))

    const document = window.document
    const button = document.querySelector("#my-button")

    // Note: Each click kicks off some callbacks inside elm-spec. Because we are 'outside' elm-spec
    // at this point, we need to wait a turn through the event loop for these callbacks to resolve
    // and the view to be updated. Otherwise the callbacks would stack up and we'd have
    // to wait some indeterminate amount of time.
    button.click()
    await wait()
    button.click()
    await wait()
    button.click()
    await wait()

    const label = document.querySelector("#my-count")
    return label.textContent
  }).then((text) => {
    expect(text).to.equal("The count is 10!")
    done()
  }).catch((err) => {
    done(err)
  })
}

const expectObservation = (observation, summary, description, conditions) => {
  expect(observation.summary).to.equal(summary)
  expect(observation.description).to.equal(description)
  expect(observation.conditions).to.deep.equal(conditions)
}