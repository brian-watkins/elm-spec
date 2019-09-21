const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("list observers", () => {
  describe("hasLength", () => {
    it("uses the hasLength observer as expected", (done) => {
      expectSpec("ListObserverSpec", "hasLength", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Expected list to have length", "3"),
          reportLine("but it has length", "1")
        ])
      })
    })
  })

  describe("isList", () => {
    it("uses the isListMatcher as expected", (done) => {
      expectSpec("ListObserverSpec", "isList", done, (observations) => {
        expectAccepted(observations[0])

        expectRejected(observations[1], [
          reportLine("List failed to match at position 2"),
          reportLine("Expected", "\"something\""),
          reportLine("to equal", "\"2\"")
        ])

        expectRejected(observations[2], [
          reportLine("List failed to match"),
          reportLine("Expected list to have length", "2"),
          reportLine("but it has length", "4")
        ])
      })
    })
  })
})