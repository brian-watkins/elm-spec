const {
  expectSpec,
  expectPassingSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("html observers", () => {
  describe("text", () => {
    it("applies the claim to the text", (done) => {
      expectSpec("HtmlObserverSpec", "text", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Claim rejected for selector", "#my-activity"),
          reportLine("Claim rejected for element text"),
          reportLine("Actual", "\"My activity is: football!\""),
          reportLine("does not equal expected", "\"football\"")
        ])
      })
    })
  })

  describe("attribute", () => {
    it("observes attributes and applies a claim", (done) => {
      expectSpec("HtmlObserverSpec", "attribute", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Claim rejected for selector", "#activity"),
          reportLine("Claim rejected for attribute", "data-fun-activity"),
          reportLine("Expected", "bowling"),
          reportLine("to contain 1 instance of", "fishing"),
          reportLine("but the text was found 0 times")
        ])
        expectAccepted(observations[2])
      })
    })
  })

  describe("hasProperty", () => {
    it("observes properties of elements as expected", (done) => {
      expectSpec("HtmlObserverSpec", "hasProperty", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Claim rejected for selector", "button"),
          reportLine("Unable to decode JSON for property", "Problem with the given value:\n\n{}\n\nExpecting an OBJECT with a field named `something_it_does_not_have`")
        ])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
      })
    })
  })
})
