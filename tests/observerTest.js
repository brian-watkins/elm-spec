const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("observer", () => {
  describe("satisfying", () => {
    it("uses the satisfying function as expected", (done) => {
      expectSpec("ObserverSpec", "satisfying", done, (observations) => {
        expectAccepted(observations[0])
        
        expectRejected(observations[1], [
          reportLine("Expected all claims to be satisfied, but one or more were rejected"),
          reportLine("Expected", "\"running\""),
          reportLine("to equal", "\"bowling\"")
        ])

        expectRejected(observations[2], [
          reportLine("Expected all claims to be satisfied, but one or more were rejected"),
          reportLine("Expected", "\"running\""),
          reportLine("to equal", "\"bowling\""),
          reportLine("and"),
          reportLine("Expected", "19"),
          reportLine("to equal", "27")
        ])
      })
    })
  })
})