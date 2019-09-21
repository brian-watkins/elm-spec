const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("observer", () => {
  describe("satisfying", () => {
    it("uses the satisfying function as expected", (done) => {
      expectSpec("ObserverSpec", "satisfying", done, (observations) => {
        expectAccepted(observations[0])
        
        expectRejected(observations[1], [
          reportLine("Expected all observers to be satisfied, but one or more was rejected"),
          reportLine("Expected", "\"bowling\""),
          reportLine("to equal", "\"running\"")
        ])

        expectRejected(observations[2], [
          reportLine("Expected all observers to be satisfied, but one or more was rejected"),
          reportLine("Expected", "\"bowling\""),
          reportLine("to equal", "\"running\""),
          reportLine("and"),
          reportLine("Expected", "27"),
          reportLine("to equal", "19")
        ])
      })
    })
  })
})