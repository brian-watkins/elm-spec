const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("Events", () => {
  context("click", () => {
    it("handles the click event as expected", (done) => {
      expectSpec("EventSpec", "click", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectRejected(observations[3], [
          reportLine("No element targeted for event", "click")
        ])
      })
    })
  })

  context("double click", () => {
    it("handles the double click event as expected", (done) => {
      expectSpec("EventSpec", "doubleClick", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
        expectRejected(observations[4], [
          reportLine("No element targeted for event", "doubleClick")
        ])
      })
    })
  })

  context("press", () => {
    it("handles the mousedown event as expected", (done) => {
      expectSpec("EventSpec", "mouseDown", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("No element targeted for event", "mousedown")
        ])
      })
    })
  })

  context("release", () => {
    it("handles the mouseup event as expected", (done) => {
      expectSpec("EventSpec", "mouseUp", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("No element targeted for event", "mouseup")
        ])
      })
    })
  })

  context("mouseMoveIn", () => {
    it("handles the mouseOver and mouseEnter events as expected", (done) => {
      expectSpec("EventSpec", "mouseMoveIn", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejected(observations[2], [
          reportLine("No element targeted for event", "mouseMoveIn")
        ])
      })
    })
  })

  context("mouseMoveOut", () => {
    it("handles the mouseOut and mouseLeave events as expected", (done) => {
      expectSpec("EventSpec", "mouseMoveOut", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejected(observations[2], [
          reportLine("No element targeted for event", "mouseMoveOut")
        ])
      })
    })
  })

  describe("Input", () => {
    context("when text is input to a targeted field", () => {
      it("updates the model and renders the view as expected", (done) => {
        expectSpec("EventSpec", "input", done, (observations) => {
          expectAccepted(observations[0])
          expectRejected(observations[1], [
            reportLine("No element targeted for event", "input")
          ])
        })
      })
    })
  })

  describe("custom events", () => {
    context("when a custom event is triggered", () => {
      it("updates as expected", (done) => {
        expectSpec("EventSpec", "custom", done, (observations) => {
          expectAccepted(observations[0])
          expectRejected(observations[1], [
            reportLine("No element targeted for event", "keyup")
          ])
        })
      })
    })
  })
})