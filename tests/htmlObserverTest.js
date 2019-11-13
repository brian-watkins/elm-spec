const {
  expectSpec,
  expectPassingSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("html observers", () => {
  describe("hasText", () => {
    it("observes the text of the selected element", (done) => {
      expectSpec("HtmlObserverSpec", "hasText", done, (observations) => {
        expectAccepted(observations[0])

        expectRejected(observations[1], [
          reportLine("Claim rejected for selector", "#my-activity"),
          reportLine("Expected text", "Something not present"),
          reportLine("but the actual text was", "My activity is: Running!")
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
          reportLine("Expected element to have attribute", "data-unknown-attribute"),
          reportLine("but it has only these attributes", "data-fun-activity, id")
        ])

        expectRejected(observations[2], [
          reportLine("Claim rejected for selector", "#activity"),
          reportLine("Expected element to have attribute", "data-fun-activity = running"),
          reportLine("but it has", "data-fun-activity = bowling")
        ])

        expectRejected(observations[3], [
          reportLine("Claim rejected for selector", "h1"),
          reportLine("Expected element to have attribute", "data-fun-activity"),
          reportLine("but it has no attributes")
        ])
      })
    })
  })
})
