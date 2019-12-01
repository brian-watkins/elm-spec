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
          reportLine("The elm-spec javascript API version is", "10"),
          reportLine("but your elm-spec runner expects a version of", "8"),
          reportLine("Upgrade to make the versions match.")
        ])
      })
    })
  })
})