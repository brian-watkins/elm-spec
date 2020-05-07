const { expectSpec, expectAccepted } = require("./helpers/SpecHelpers")

describe("programs with request animation frame", () => {
  context("subscribed to request animation frame and triggering commands that wait for the next frame", () => {
    it("runs the scenario as expected", (done) => {
      expectSpec("RequestAnimationSpec", "onFrame", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })
})