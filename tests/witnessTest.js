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
          expect(observations[1].report).to.deep.equal([
            { statement: "Expected witness", detail: "injected" },
            { statement: "to have been called", detail: "17 times" },
            { statement: "but it was called", detail: "1 time" }
          ])
          expect(observations[2].report).to.deep.equal([
            { statement: "Expected witness", detail: "some-other-witness" },
            { statement: "to have been called", detail: "1 time" },
            { statement: "but it was called", detail: "0 times" }
          ])
        })
      })
    })
  })
})