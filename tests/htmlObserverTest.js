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
          reportLine("Element text does not satisfy claim"),
          reportLine("Expected", "\"My activity is: football!\""),
          reportLine("to equal", "\"football\"")
        ])
      })
    })
  })

  describe("hasText", () => {
    it("observes the text of the selected element", (done) => {
      expectSpec("HtmlObserverSpec", "hasText", done, (observations) => {
        expectAccepted(observations[0])

        expectRejected(observations[1], [
          reportLine("Claim rejected for selector", "#my-activity"),
          reportLine("Element text does not satisfy claim"),
          reportLine("Expected", "My activity is: Running!"),
          reportLine("to contain 1 instance of", "Something not present"),
          reportLine("but the text was found 0 times")
        ])
      })
    })

    it("observes that text is contained in the text content of the element", (done) => {
      expectPassingSpec("HtmlObserverSpec", "hasTextContained", done)
    })
  })

  describe("hasAttribute", () => {
    it("observes attributes of selected elements as expected", (done) => {
      expectSpec("HtmlObserverSpec", "hasAttribute", done, (observations) => {
        expectAccepted(observations[0])
        
        expectRejected(observations[1], [
          reportLine("Claim rejected for selector", "#activity"),
          reportLine("Claim rejected for attribute", "data-unknown-attribute"),
          reportLine("Expected attribute to have value", "bowling"),
          reportLine("but the element has no such attribute")
        ])

        expectRejected(observations[2], [
          reportLine("Claim rejected for selector", "#activity"),
          reportLine("Claim rejected for attribute", "data-fun-activity"),
          reportLine("Expected attribute to have value", "running"),
          reportLine("but it has", "bowling")
        ])

        expectRejected(observations[3], [
          reportLine("Claim rejected for selector", "h1"),
          reportLine("Claim rejected for attribute", "data-fun-activity"),
          reportLine("Expected attribute to have value", "running"),
          reportLine("but the element has no such attribute")
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
