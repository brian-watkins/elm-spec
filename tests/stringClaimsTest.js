const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("string claims", () => {
  context("contains", () => {
    it("determines whether the string contains the expected string", (done) => {
      expectSpec("StringClaimsSpec", "contains", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejected(observations[2], [
          reportLine("Expected", "fun"),
          reportLine("to contain 4 instances of", "blah"),
          reportLine("but the text was found 0 times")
        ])
        expectRejected(observations[3], [
          reportLine("Expected", "blah blah blahblah apple"),
          reportLine("to contain 1 instance of", "blah"),
          reportLine("but the text was found 4 times")
        ])
        expectRejected(observations[4], [
          reportLine("Expected", "blah apple"),
          reportLine("to contain 0 instances of", "blah"),
          reportLine("but the text was found 1 time")
        ])
      })
    })
  })
})