const chai = require('chai')
const expect = chai.expect
const { expectSpec, expectFailingSpec, expectPassingSpec } = require('./helpers/SpecHelpers')

describe("Expect Model", () => {
  
  describe("When the spec is not observed to be valid", () => {
    it("sends a failure message", (done) => {
      expectFailingSpec("ExpectModelSpec", "failing", done, (observations) => {
        expect(observations).to.have.length(1)
        expect(observations[0].message).to.equal("Expected 17 to equal 99, but it does not.")
      })
    })

    it("provides the spec description", (done) => {
      expectFailingSpec("ExpectModelSpec", "failing", done, (observations) => {
        expect(observations).to.have.length(1)
        expect(observations[0].description).to.equal("It fails")
      })
    })
  })

  describe("When the spec is observed to be valid", () => {
    it("sends a success message", (done) => {
      expectPassingSpec("ExpectModelSpec", "passing", done)
    })

    it("provides the spec description", (done) => {
      expectPassingSpec("ExpectModelSpec", "passing", done, (observations) => {
        expect(observations).to.have.length(1)
        expect(observations[0].description).to.equal("It contains the expected value")
      })
    })
  })

  describe("When the spec has multiple observations", () => {
    it("provides all the observation results", (done) => {
      expectSpec("ExpectModelSpec", "multiple", done, (observations) => {
        expect(observations).to.have.length(2)
        expect(observations[0].summary).to.equal("ACCEPT")
        expect(observations[0].description).to.equal("It contains the expected number")
        expect(observations[1].summary).to.equal("REJECT")
        expect(observations[1].description).to.equal("It contains the expected name")
        expect(observations[1].message).to.equal("Expected \"awesome-spec\" to equal \"fun-spec\", but it does not.")
      })
    })
  })

})