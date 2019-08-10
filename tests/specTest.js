const chai = require('chai')
const expect = chai.expect
const { expectPassingSpec, expectSpec } = require('./helpers/SpecHelpers')

describe("spec", () => {
  describe("when there are multiple when blocks", () => {
    it("processes the steps as expected", (done) => {
      expectPassingSpec("SpecSpec", "multipleWhen", done)
    })

    it("sends all the conditions", (done) => {
      expectPassingSpec("SpecSpec", "", done, (observations) => {
        expect(observations[0].conditions).to.deep.equal([
          "Given a test worker",
          "When the first sub is sent",
          "When a second sub is sent",
          "When a third sub is sent"
        ])
      })
    })
  })

  describe("when there are multiple scenarios", () => {
    it("executes the observations in each scenario", (done) => {
      expectSpec("SpecSpec", "scenarios", done, (observations) => {
        expect(observations).to.have.length(4)
        
        expectObservation(observations[0], "ACCEPT", "It records the first number",
          [ "Given a test worker",
            "When the first sub is sent"
          ]
        )

        expectObservation(observations[1], "ACCEPT", "It records the second awesome number",
          [ "Given a test worker",
            "When the first sub is sent",
            "Given an awesome scenario",
            "When another awesome sub is sent"
          ]
        )

        expectObservation(observations[2], "ACCEPT", "It records the second number",
          [ "Given a test worker", 
            "When the first sub is sent",
            "Given another scenario",
            "When another sub is sent"
          ]
        )

        expectObservation(observations[3], "ACCEPT", "It records the final number",
          [ "Given a test worker",
            "When the first sub is sent",
            "Given another scenario",
            "When another sub is sent",
            "Given a final scenario",
            "When the final sub is sent"
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