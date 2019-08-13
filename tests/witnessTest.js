const chai = require('chai')
const expect = chai.expect
const { expectSpec } = require("./helpers/SpecHelpers")

describe("witness", () => {
  describe("spy was called", () => {
    it("runs the spec as expected", (done) => {
      expectSpec("WitnessSpec", "spy", done, (observations) => {
        expect(observations).to.have.length(3)
        expect(observations[0].summary).to.equal("ACCEPT")
        expect(observations[1].summary).to.equal("REJECT")
        expect(observations[2].summary).to.equal("REJECT")
      })
    })
    
    describe("when the observation is rejected", () => {
      it("pluralizes the error message as expected", (done) => {
        expectSpec("WitnessSpec", "spy", done, (observations) => {
          expect(observations[1].message).to.equal("Expected witness\n\tinjected\nto have been called 17 times, but it was called 1 time.")
          expect(observations[2].message).to.equal("Expected witness\n\tsome-other-witness\nto have been called 1 time, but it was called 0 times.")
        })
      })
    })
  })
})