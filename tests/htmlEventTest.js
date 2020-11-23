const {
  expectSpec,
  expectAccepted,
} = require("./helpers/SpecHelpers")
const {
  expectRejectedWhenDocumentTargeted,
  expectRejectedOnViewReRender,
  expectRejectedWhenNoElementTargeted
} = require("./helpers/eventTestHelpers")

describe("Events", () => {
  context("click", () => {
    it("handles the click event as expected", (done) => {
      expectSpec("EventSpec", "click", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectRejectedWhenNoElementTargeted("click", observations[3])
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
        expectRejectedWhenNoElementTargeted("doubleClick", observations[4])
        expectRejectedOnViewReRender(observations[5])
      })
    })
  })

  context("press", () => {
    it("handles the mousedown event as expected", (done) => {
      expectSpec("EventSpec", "mouseDown", done, (observations) => {
        expectAccepted(observations[0])
        expectRejectedWhenNoElementTargeted("mousedown", observations[1])
        expectRejectedOnViewReRender(observations[2])
      })
    })
  })

  context("release", () => {
    it("handles the mouseup event as expected", (done) => {
      expectSpec("EventSpec", "mouseUp", done, (observations) => {
        expectAccepted(observations[0])
        expectRejectedWhenNoElementTargeted("mouseup", observations[1])
        expectRejectedOnViewReRender(observations[2])
      })
    })
  })

  context("mouseMoveIn", () => {
    it("handles the mouseOver and mouseEnter events as expected", (done) => {
      expectSpec("EventSpec", "mouseMoveIn", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejectedWhenNoElementTargeted("mouseMoveIn", observations[2])
        expectRejectedWhenDocumentTargeted("mouseMoveIn", observations[3])
        expectRejectedOnViewReRender(observations[4])
      })
    })
  })

  context("mouseMoveOut", () => {
    it("handles the mouseOut and mouseLeave events as expected", (done) => {
      expectSpec("EventSpec", "mouseMoveOut", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejectedWhenNoElementTargeted("mouseMoveOut", observations[2])
        expectRejectedWhenDocumentTargeted("mouseMoveOut", observations[3])
        expectRejectedOnViewReRender(observations[4])
      })
    })
  })

  describe("custom events", () => {
    context("when a custom event is triggered", () => {
      it("updates as expected", (done) => {
        expectSpec("EventSpec", "custom", done, (observations) => {
          expectAccepted(observations[0])
          expectRejectedWhenNoElementTargeted("keyup", observations[1])
          expectRejectedOnViewReRender(observations[2])
        })
      })
    })
    context("when a custom event with custom target properties is triggered", () => {
      it("updates as expected", (done) => {
        expectSpec("CustomTargetEventSpec", "customTarget", done, (observations) => {
          expectAccepted(observations[0])
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


