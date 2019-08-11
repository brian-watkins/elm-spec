const { expectPassingSpec } = require("./helpers/SpecHelpers")
const chai = require('chai')
const expect = chai.expect


describe("time plugin", () => {
  it("allows the spec to control Time.every as necessary", (done) => {
    expectPassingSpec("TimeSpec", "", done)
  })
})