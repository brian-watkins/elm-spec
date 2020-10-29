const chai = require('chai')
const expect = chai.expect
const {
  expectSpec,
  expectAccepted,
  reportLine,
  isForRealBrowser,
  expectRejected
 } = require("./helpers/SpecHelpers")

describe("programs with request animation frame", () => {
  context("minimal request animation frame subscription example", () => {
    context("when allowing extra animation frames", () => {
      it("runs the animation frames as expected", (done) => {
        expectSpec("RequestAnimationSpec", "minimal", done, (observations, error, logs) => {
          expectAccepted(observations[0])
          expectAccepted(observations[1])
        })
      })  
    })
    context("when not allowing extra animation frames", () => {
      it("aborts the test run at the first sign of an extra animation frame", (done) => {
        expectSpec("RequestAnimationSpec", "fail", done, (observations) => {
          expect(observations).to.have.length(1)
          expectRejected(observations[0], [
            reportLine("A spec step results in extra animation frame tasks!"),
            reportLine("See the documentation for Spec.Time.nextAnimationFrame for more details."),
            reportLine("Set up this scenario with Spec.Time.allowExtraAnimationFrames to ignore this warning.")
          ])
        })
      })
    })
  })
  context("when the view updates on animation frame", () => {
    it("updates the view", (done) => {
      expectSpec("RequestAnimationSpec", "view", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })
  context("next animation frame does not trigger an update", () => {
    it("does nothing", (done) => {
      expectSpec("RequestAnimationSpec", "noUpdate", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })
  context("dom updates", () => {
    it("triggers multiple dom events", (done) => {
      expectSpec("RequestAnimationSpec", "domUpdate", done, (observations) => {
        expectAccepted(observations[0])
        if (isForRealBrowser()) {
          expectAccepted(observations[1])
        } else {
          expectRejected(observations[1], [
            reportLine("Actual", "{ x = 0, y = -10 }"),
            reportLine("does not equal expected", "{ x = 0, y = 46 }")
          ])
        }
      })
    })
    it("handles dom events when there is an input event also", (done) => {
      expectSpec("RequestAnimationSpec", "input", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })
  context("animation frame failures", () => {
    context("the extra frames are not allowed after a scenario that does allow them", () => {
      it("fails the second scenario only", (done) => {
        expectSpec("RequestAnimationSpec", "someFailure", done, (observations) => {
          expectAccepted(observations[0])
          expectRejected(observations[1], [
            reportLine("A spec step results in extra animation frame tasks!"),
            reportLine("See the documentation for Spec.Time.nextAnimationFrame for more details."),
            reportLine("Set up this scenario with Spec.Time.allowExtraAnimationFrames to ignore this warning.")
          ])
        })
      })
    })
  })
  context("subscribed to request animation frame and triggering commands that wait for the next frame", () => {
    it("runs the scenario as expected", (done) => {
      expectSpec("RequestAnimationSpec", "onFrame", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
      })
    })
  })
  context("multiple scenarios with extra animation frames", () => {
    it("runs both scenarios as expected", (done) => {
      expectSpec("RequestAnimationSpec", "multipleScenarios", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })
})