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
        expectRejectedOnNoElementTargeted("click", observations[3])
        expectRejectedOnViewReRender(observations[4])
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
        expectRejectedOnNoElementTargeted("doubleClick", observations[4])
        expectRejectedOnViewReRender(observations[5])
      })
    })
  })

  context("press", () => {
    it("handles the mousedown event as expected", (done) => {
      expectSpec("EventSpec", "mouseDown", done, (observations) => {
        expectAccepted(observations[0])
        expectRejectedOnNoElementTargeted("mousedown", observations[1])
        expectRejectedOnViewReRender(observations[2])
      })
    })
  })

  context("release", () => {
    it("handles the mouseup event as expected", (done) => {
      expectSpec("EventSpec", "mouseUp", done, (observations) => {
        expectAccepted(observations[0])
        expectRejectedOnNoElementTargeted("mouseup", observations[1])
        expectRejectedOnViewReRender(observations[2])
      })
    })
  })

  context("mouseMoveIn", () => {
    it("handles the mouseOver and mouseEnter events as expected", (done) => {
      expectSpec("EventSpec", "mouseMoveIn", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejectedOnNoElementTargeted("mouseMoveIn", observations[2])
        expectRejectedOnViewReRender(observations[3])
      })
    })
  })

  context("mouseMoveOut", () => {
    it("handles the mouseOut and mouseLeave events as expected", (done) => {
      expectSpec("EventSpec", "mouseMoveOut", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejectedOnNoElementTargeted("mouseMoveOut", observations[2])
        expectRejectedOnViewReRender(observations[3])
      })
    })
  })

  describe("custom events", () => {
    context("when a custom event is triggered", () => {
      it("updates as expected", (done) => {
        expectSpec("EventSpec", "custom", done, (observations) => {
          expectAccepted(observations[0])
          expectRejectedOnNoElementTargeted("keyup", observations[1])
          expectRejectedOnViewReRender(observations[2])
        })
      })
    })
  })

  describe("no handler", () => {
    it("does nothing when there is no handler", (done) => {
      expectSpec("EventSpec", "noHandler", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })
})

const expectRejectedOnNoElementTargeted = (eventName, observation) => {
  expectRejected(observation, [
    reportLine("No element targeted for event", eventName)
  ])
}

const expectRejectedOnViewReRender = (observation) => {
  expectRejected(observation, [
    reportLine("No match for selector", "#conditional")
  ])
}