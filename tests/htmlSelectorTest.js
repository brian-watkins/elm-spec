const { expectPassingBrowserSpec } = require("./helpers/SpecHelpers")

describe("Selectors", () => {
  describe("tag", () => {
    context("when an element is selected by tag name", () => {
      it("selects the element as epxected", (done) => {
        expectPassingBrowserSpec("SelectorSpec", "tag", done)
      })
    })
    context("when more than one tag selector is used in a selection", () => {
      it("uses only the first tag", (done) => {
        expectPassingBrowserSpec("SelectorSpec", "onlyOneTag", done)
      })
    })
    context("when a tag selector is combined with other selectors", () => {
      it("selects the element as expected", (done) => {
        expectPassingBrowserSpec("SelectorSpec", "combinedTag", done)
      })
    })
  })

  describe("attributeName", () => {
    it("selects the element as expected", (done) => {
      expectPassingBrowserSpec("SelectorSpec", "attributeName", done)
    })
  })

  describe("descendantsOf", () => {
    it("selects the elements as expected", (done) => {
      expectPassingBrowserSpec("SelectorSpec", "descendants", done)
    })
  })
})