const { expectPassingSpec } = require("./helpers/SpecHelpers")

describe("Selectors", () => {
  describe("tag", () => {
    context("when an element is selected by tag name", () => {
      it("selects the element as epxected", (done) => {
        expectPassingSpec("SelectorSpec", "tag", done)
      })
    })
    context("when more than one tag selector is used in a selection", () => {
      it("uses only the first tag", (done) => {
        expectPassingSpec("SelectorSpec", "onlyOneTag", done)
      })
    })
    context("when a tag selector is combined with other selectors", () => {
      it("selects the element as expected", (done) => {
        expectPassingSpec("SelectorSpec", "combinedTag", done)
      })
    })
  })

  describe("attributeName", () => {
    it("selects the element as expected", (done) => {
      expectPassingSpec("SelectorSpec", "attributeName", done)
    })
  })

  describe("attribute", () => {
    it("selects the element as expected", (done) => {
      expectPassingSpec("SelectorSpec", "attribute", done)
    })
  })

  describe("descendantsOf", () => {
    it("selects the elements as expected", (done) => {
      expectPassingSpec("SelectorSpec", "descendants", done)
    })
  })
})