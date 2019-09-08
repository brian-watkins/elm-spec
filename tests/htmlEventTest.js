const { expectPassingBrowserSpec } = require("./helpers/SpecHelpers")

describe("Events", () => {
  describe("Input", () => {
    context("when text is input to a targeted field", () => {
      it("updates the model and renders the view as expected", (done) => {
        expectPassingBrowserSpec("EventSpec", "input", done)
      })
    })
  })
})