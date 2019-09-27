const { expectBrowserSpec, expectAccepted } = require("./helpers/SpecHelpers")

describe("Navigation", () => {
  context("when a new url is loaded", () => {
    it("performs the spec as expected", (done) => {
      expectBrowserSpec("NavigationSpec", "loadUrl", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })
})