const chai = require('chai')
const expect = chai.expect
const { Elm } = require('./specs.js')
const { expectSpec, expectFailingSpec, expectPassingSpec } = require('./helpers/SpecHelpers')

describe("Expect Model", () => {
  
  describe("When the spec is not observed to be valid", () => {
    it("sends a failure message", (done) => {
      expectFailingSpec(Elm.Specs.ExpectModelSpec, "failing", done, (observations) => {
        expect(observations).to.have.length(1)
        expect(observations[0].message).to.equal("Expected 17 to equal 99, but it does not.")
      })
    })

    it("provides the spec description", (done) => {
      expectFailingSpec(Elm.Specs.ExpectModelSpec, "failing", done, (observations) => {
        expect(observations).to.have.length(1)
        expect(observations[0].description).to.equal("it fails")
      })
    })
  })

  describe("When the spec is observed to be valid", () => {
    it("sends a success message", (done) => {
      expectPassingSpec(Elm.Specs.ExpectModelSpec, "passing", done)
    })

    it("provides the spec description", (done) => {
      expectPassingSpec(Elm.Specs.ExpectModelSpec, "passing", done, (observations) => {
        expect(observations).to.have.length(1)
        expect(observations[0].description).to.equal("it contains the expected value")
      })
    })
  })

  describe("When the spec has multiple observations", () => {
    it("provides all the observation results", (done) => {
      expectSpec(Elm.Specs.ExpectModelSpec, "multiple", done, (observations) => {
        expect(observations).to.have.length(2)
        expect(observations[0].summary).to.equal("ACCEPT")
        expect(observations[0].description).to.equal("it contains the expected number")
        expect(observations[1].summary).to.equal("REJECT")
        expect(observations[1].description).to.equal("it contains the expected name")
        expect(observations[1].message).to.equal("Expected \"awesome-spec\" to equal \"fun-spec\", but it does not.")
      })
    })
  })

})