const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("list observers", () => {
  describe("isListWithLength", () => {
    it("uses the isListWithLength observer as expected", (done) => {
      expectSpec("ListObserverSpec", "isListWithLength", done, (observations) => {
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
          reportLine("Expected", "\"2\""),
          reportLine("to equal", "\"something\"")
        ])

        expectRejected(observations[2], [
          reportLine("List failed to match"),
          reportLine("Expected list to have length", "2"),
          reportLine("but it has length", "4")
        ])
      })
    })
  })

  describe("atIndex", () => {
    it("observes elements at the given index as expected", (done) => {
      expectSpec("ListObserverSpec", "atIndex", done, (observations) => {
        expectAccepted(observations[0])

        expectRejected(observations[1], [
          reportLine("Item at index 2 did not satisfy claim:"),
          reportLine("Expected", "\"3\""),
          reportLine("to equal", "\"17\"")
        ])

        expectRejected(observations[2], [
          reportLine("Expected item at index", "22"),
          reportLine("but the list has length", "4")
        ])
      })
    })
  })
})