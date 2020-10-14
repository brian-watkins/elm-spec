const { expectSpec, expectAccepted } = require("./helpers/SpecHelpers")

describe("programs with request animation frame", () => {
  context("minimal request animation frame subscription example", () => {
    it("updates the model on each animation frame", (done) => {
      expectSpec("RequestAnimationSpec", "minimal", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
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
  context("subscribed to request animation frame and triggering commands that wait for the next frame", () => {
    it("runs the scenario as expected", (done) => {
      expectSpec("RequestAnimationSpec", "onFrame", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
      })
    })
  })
})