const chai = require('chai')
const expect = chai.expect
const { Elm } = require('./specs.js')
const { expectPassingSpec } = require('./helpers/SpecHelpers')

describe("spec", () => {
  describe("when there are multiple when blocks", () => {
    it("processes the steps as expected", (done) => {
      expectPassingSpec(Elm.Specs.SpecSpec, "", done)
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
})