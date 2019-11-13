const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("browser events", () => {
  context("keyboard events", () => {
    it("handles browser keyboard events", (done) => {
      expectSpec("BrowserEventSpec", "keyboard", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("click events", () => {
    it("handles browser click events", (done) => {
      expectSpec("BrowserEventSpec", "click", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
      })
    })
  })

  context("mouseDown events", () => {
    it("handles browser mouseDown events", (done) => {
      expectSpec("BrowserEventSpec", "mouseDown", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("mouseUp events", () => {
    it("handles browser mouseUp events", (done) => {
      expectSpec("BrowserEventSpec", "mouseUp", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("mouseMove events", () => {
    it("handles browser mouseMove events", (done) => {
      expectSpec("BrowserEventSpec", "mouseMove", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("window resize", () => {
    it("handles the window resize as expected", (done) => {
      expectSpec("BrowserEventSpec", "windowResize", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("window visibility", () => {
    it("handles the window visibility change as expected", (done) => {
      expectSpec("BrowserEventSpec", "windowVisibility", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("animationFrame events", () => {
    it("handles the animation frame events as expected", (done) => {
      expectSpec("BrowserEventSpec", "animationFrame", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("events that cannot run at the browser level", () => {
    it("fails the test", (done) => {
      expectSpec("BrowserEventSpec", "nonBrowserEvents", done, (observations) => {
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