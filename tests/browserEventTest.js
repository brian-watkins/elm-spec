const {
  expectBrowserSpec,
  expectAccepted,
  expectRejected,
  reportLine
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

  context("mouseDown events", () => {
    it("handles browser mouseDown events", (done) => {
      expectBrowserSpec("BrowserEventSpec", "mouseDown", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("mouseUp events", () => {
    it("handles browser mouseUp events", (done) => {
      expectBrowserSpec("BrowserEventSpec", "mouseUp", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("mouseMove events", () => {
    it("handles browser mouseMove events", (done) => {
      expectBrowserSpec("BrowserEventSpec", "mouseMove", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("events that cannot run at the browser level", () => {
    it("fails the test", (done) => {
      expectBrowserSpec("BrowserEventSpec", "nonBrowserEvents", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("Event not supported when document is targeted", "mouseMoveIn")
        ])
        expectRejected(observations[1], [
          reportLine("Event not supported when document is targeted", "mouseMoveOut")
        ])
      })
    })
  })
})