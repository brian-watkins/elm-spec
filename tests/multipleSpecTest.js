const chai = require('chai')
const expect = chai.expect
const { expectProgram } = require("./helpers/SpecHelpers")

describe("multiple specs", () => {
  it("runs all the provided specs", (done) => {
    expectProgram("MultipleSpecSpec", done, (observations) => {
      expect(observations).to.have.length(4)
    })
  })
})