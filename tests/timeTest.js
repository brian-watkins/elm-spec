const { expectPassingSpec } = require("./helpers/SpecHelpers")
const chai = require('chai')
const expect = chai.expect


describe("time plugin", () => {
  it("allows the spec to control Time.every as necessary", (done) => {
    expectPassingSpec("TimeSpec", "", done)
  })

  describe("when the program uses Process.sleep", () => {
    it("processes the command as expected", (done) => {
      expectPassingSpec("SleepSpec", "sleep", done)
    })

    it("processes only tasks that have occured during the ticks", (done) => {
      expectPassingSpec("SleepSpec", "delay", done)
    })
  })
})