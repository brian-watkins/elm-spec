const {
  expectBrowserSpec,
  expectAccepted
} = require("./helpers/SpecHelpers")

describe("browser events", () => {
  context("keyboard events", () => {
    it("handles browser keyboard events", (done) => {
      expectBrowserSpec("BrowserEventSpec", "keyboard", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })
})