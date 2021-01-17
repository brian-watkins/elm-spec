const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("Observer functions", () => {
  context("focus", () => {
    it("focuses the observer as expected", (done) => {
      expectSpec("ObserverSpec", "focus", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Claim rejected for selector", "#something-not-present"),
          reportLine("Expected", "something"),
          reportLine("but found", "nothing")
        ])
      })
    })  
  })
})