const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("observer", () => {
  describe("satisfying", () => {
    it("uses the satisfying function as expected", (done) => {
      expectSpec("ClaimSpec", "satisfying", done, (observations) => {
        expectAccepted(observations[0])
        
        expectRejected(observations[1], [
          reportLine("Expected all claims to be satisfied, but one or more were rejected"),
          reportLine("Expected", "\"bowling\""),
          reportLine("to equal", "\"should fail\"")
        ])

        expectRejected(observations[2], [
          reportLine("Expected all claims to be satisfied, but one or more were rejected"),
          reportLine("Expected", "\"bowling\""),
          reportLine("to equal", "\"should fail\""),
          reportLine("and"),
          reportLine("Expected", "19"),
          reportLine("to equal", "27")
        ])
      })
    })
  })

  describe("boolean claims", () => {
    it("handles boolean claims", (done) => {
      expectSpec("ClaimSpec", "boolean", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejected(observations[2], [
          reportLine("Expected", "True"),
          reportLine("to equal", "False")
        ])
      })
    })
  })

  describe("claims about maybe values", () => {
    it("applies a claim to the value", (done) => {
      expectSpec("ClaimSpec", "isSomethingWhere", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Expected", "\"hello\""),
          reportLine("to equal", "\"blah\"")
        ])
        expectRejected(observations[2], [
          reportLine("Expected", "something"),
          reportLine("but found", "nothing")
        ])
      })
    })
  })

  describe("require", () => {
    it("applies require as expected", (done) => {
      expectSpec("ClaimSpec", "require", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })
})