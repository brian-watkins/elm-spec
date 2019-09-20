const chai = require('chai')
const expect = chai.expect
const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("witness", () => {
  describe("spy was called", () => {
    it("runs the spec as expected", (done) => {
      expectSpec("WitnessSpec", "spy", done, (observations) => {
        expect(observations).to.have.length(3)
        expectAccepted(observations[0])
      })
    })
    
    describe("when the observation is rejected", () => {
      it("pluralizes the error message as expected", (done) => {
        expectSpec("WitnessSpec", "spy", done, (observations) => {
          expectRejected(observations[1], [
            reportLine("Expected witness", "injected"),
            reportLine("to have been called", "1 time"),
            reportLine("but it was called", "0 times")
          ])
          expectRejected(observations[2], [
            reportLine("Expected witness", "injected"),
            reportLine("to have been called", "17 times"),
            reportLine("but it was called", "1 time")
          ])
        })
      })
    })
  })
})