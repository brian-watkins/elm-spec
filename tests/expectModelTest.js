const chai = require('chai')
const expect = chai.expect
const {
  expectSpec,
  expectPassingSpec,
  expectRejected,
  reportLine,
  expectAccepted
} = require('./helpers/SpecHelpers')

describe("Expect Model", () => {
  
  describe("When the spec is not observed to be valid", () => {
    it("sends a failure message", (done) => {
      expectSpec("ExpectModelSpec", "failing", done, (observations) => {
        expect(observations).to.have.length(1)
        expectRejected(observations[0], [
          reportLine("Expected", "99"),
          reportLine("to equal", "17")
        ])
      })
    })

    it("provides the spec description", (done) => {
      expectSpec("ExpectModelSpec", "failing", done, (observations) => {
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
        expectAccepted(observations[0])
        expect(observations[0].description).to.equal("It contains the expected number")
        
        expectRejected(observations[1], [
          reportLine("Expected", "\"fun-spec\""),
          reportLine("to equal", "\"awesome-spec\"")
        ])
        expect(observations[1].description).to.equal("It contains the expected name")
      })
    })
  })

})