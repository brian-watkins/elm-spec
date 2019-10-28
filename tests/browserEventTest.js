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

  context("click events", () => {
    it("handles browser click events", (done) => {
      expectBrowserSpec("BrowserEventSpec", "click", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
      })
    })
  })
})