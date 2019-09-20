const { expectBrowserSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("html observers", () => {
  describe("hasAttribute", () => {
    it("observes attributes of selected elements as expected", (done) => {
      expectBrowserSpec("HtmlObserverSpec", "hasAttribute", done, (observations) => {
        expectAccepted(observations[0])
        
        expectRejected(observations[1], [
          reportLine("Expected element to have attribute", "data-unknown-attribute"),
          reportLine("but it has only these attributes", "data-fun-activity, id")
        ])

        expectRejected(observations[2], [
          reportLine("Expected element to have attribute", "data-fun-activity = running"),
          reportLine("but it has", "data-fun-activity = bowling")
        ])

        expectRejected(observations[3], [
          reportLine("Expected element to have attribute", "data-fun-activity"),
          reportLine("but it has no attributes")
        ])
      })
    })
  })
})
