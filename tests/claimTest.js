const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("observer", () => {
  describe("satisfying", () => {
    it("uses the satisfying function as expected", (done) => {
      expectSpec("ClaimSpec", "satisfying", done, (observations) => {
        expectAccepted(observations[0])
        
        expectRejected(observations[1], [
          reportLine("Expected all claims to be satisfied, but one or more were rejected"),
          reportLine("Actual", "\"bowling\""),
          reportLine("does not equal expected", "\"should fail\"")
        ])

        expectRejected(observations[2], [
          reportLine("Expected all claims to be satisfied, but one or more were rejected"),
          reportLine("Actual", "\"bowling\""),
          reportLine("does not equal expected", "\"should fail\""),
          reportLine("and"),
          reportLine("Actual", "19"),
          reportLine("does not equal expected", "27")
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
          reportLine("Actual", "True"),
          reportLine("does not equal expected", "False")
        ])
      })
    })
  })

  describe("claims about maybe values", () => {
    it("applies a claim to the value", (done) => {
      expectSpec("ClaimSpec", "isSomethingWhere", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Actual", "\"hello\""),
          reportLine("does not equal expected", "\"blah\"")
        ])
        expectRejected(observations[2], [
          reportLine("Expected", "something"),
          reportLine("but found", "nothing")
        ])
      })
    })
  })

  describe("specifyThat", () => {
    it("applies specifyThat as expected", (done) => {
      expectSpec("ClaimSpec", "specifyThat", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })
})