const chai = require('chai')
const expect = chai.expect
const {
  expectProgramAtVersion,
  reportLine
 } = require("./helpers/SpecHelpers")

describe("version check", () => {
  context("when the version does not match", () => {
    it("does not run the suite", (done) => {
      expectProgramAtVersion("VersionSpec", 8, done, (observations) => {
        expect(observations).to.have.length(0)
      })
    })
    it("sends an error to the reporter", (done) => {
      expectProgramAtVersion("VersionSpec", 8, done, (observations, error) => {
        expect(error).to.deep.equal([
          reportLine("elm-spec requires elm-spec-core at version", "10.x"),
          reportLine("but your elm-spec-core version is", "8.x"),
          reportLine("Check your JavaScript runner and upgrade to make the versions match.")
        ])
      })
    })
  })
})