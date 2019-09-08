const chai = require('chai')
const expect = chai.expect
const { expectPassingSpec, expectSpec } = require('./helpers/SpecHelpers')

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
          "Describing: A Spec",
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
          [ "Describing: Multiple scenarios",
            "Scenario: the happy path",
            "When a single message is sent"
          ]
        )

        expectObservation(observations[1], "ACCEPT", "It records the numbers",
          [ "Describing: Multiple scenarios",
            "Scenario: multiple sub messages are sent",
            "When multiple messages are sent"
          ]
        )

        expectObservation(observations[2], "ACCEPT", "It records the number",
          [ "Describing: Multiple scenarios",
            "Scenario: a different message is sent",
            "When a single message is sent"
          ]
        )
      })
    })
  })
})

const expectObservation = (observation, summary, description, conditions) => {
  expect(observation.summary).to.equal(summary)
  expect(observation.description).to.equal(description)
  expect(observation.conditions).to.deep.equal(conditions)
}