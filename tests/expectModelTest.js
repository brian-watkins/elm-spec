const chai = require('chai')
const expect = chai.expect
const { Elm } = require('./specs.js')
const { expectFailingSpec, expectPassingSpec } = require('./helpers/SpecHelpers')

describe("Expect Model", () => {
  
  describe("When the spec is not observed to be valid", () => {
    it("sends a failure message", (done) => {
      expectFailingSpec(Elm.Specs.ExpectModelSpec, "failing", done, (observation) => {
        expect(observation.message).to.equal("Expected 17 to equal 99, but it does not.")
      })
    })

    it("provides the spec description", (done) => {
      expectFailingSpec(Elm.Specs.ExpectModelSpec, "failing", done, (observation) => {
        expect(observation.description).to.equal("it fails")
      })
    })
  })

  describe("When the spec is observed to be valid", () => {
    it("sends a success message", (done) => {
      expectPassingSpec(Elm.Specs.ExpectModelSpec, "passing", done)
    })

    it("provides the spec description", (done) => {
      expectPassingSpec(Elm.Specs.ExpectModelSpec, "passing", done, (observation) => {
        expect(observation.description).to.equal("it contains the expected value")
      })
    })
  })

})