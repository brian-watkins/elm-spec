const chai = require('chai')
const expect = chai.expect
const { Elm } = require('./specs.js')
const { expectPassingSpec, expectSpec } = require('./helpers/SpecHelpers')

describe("spec", () => {
  describe("when there are multiple when blocks", () => {
    it("processes the steps as expected", (done) => {
      expectPassingSpec(Elm.Specs.SpecSpec, "multipleWhen", done)
    })

    it("sends all the conditions", (done) => {
      expectPassingSpec(Elm.Specs.SpecSpec, "", done, (observations) => {
        expect(observations[0].conditions).to.deep.equal([
          "the first sub is sent",
          "a second sub is sent",
          "a third sub is sent"
        ])
      })
    })
  })

  describe("when there are multiple scenarios", () => {
    it("executes the observations in each scenario", (done) => {
      expectSpec(Elm.Specs.SpecSpec, "scenarios", done, (observations) => {
        expect(observations).to.have.length(4)
        
        expectObservation(observations[0], "ACCEPT", "it records the first number", 
          [ "the first sub is sent" ]
        )

        expectObservation(observations[1], "ACCEPT", "it records the second awesome number",
          [ "the first sub is sent",
            "another awesome sub is sent"
          ]
        )

        expectObservation(observations[2], "ACCEPT", "it records the second number",
          [ "the first sub is sent",
            "another sub is sent"
          ]
        )

        expectObservation(observations[3], "ACCEPT", "it records the final number",
          [ "the first sub is sent",
            "another sub is sent",
            "the final sub is sent"
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