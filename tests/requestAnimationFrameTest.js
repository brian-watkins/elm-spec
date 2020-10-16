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
    it("warns about extra animation frame tasks on steps, including the initial command", (done) => {
      expectSpec("RequestAnimationSpec", "minimal", done, (observations, error, logs) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expect(logs).to.deep.equal([
          [ reportLine("A spec step results in extra animation frame tasks!"),
            reportLine("See the documentation for Spec.Time.nextAnimationFrame for more details.")
          ],
          [ reportLine("A spec step results in extra animation frame tasks!"),
            reportLine("See the documentation for Spec.Time.nextAnimationFrame for more details.")
          ]
        ])
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
        if (isForRealBrowser()) {
          expectAccepted(observations[0])
        } else {
          expectRejected(observations[0], [
            reportLine("Actual", "{ x = 0, y = -10 }"),
            reportLine("does not equal expected", "{ x = 0, y = 46 }")
          ])
        }
      })
    })
  })
  context("animation frame warnings", () => {
    context("the warnings are disabled", () => {
      it("shows no warnings", (done) => {
        expectSpec("RequestAnimationSpec", "noWarnings", done, (observations, error, logs) => {
          expectAccepted(observations[0])
        })
      })
    })
    context("the warnings are not disabled after a scenario that does disable them", () => {
      it("shows the warnings for the second scenario only", (done) => {
        expectSpec("RequestAnimationSpec", "someWarnings", done, (observations, error, logs) => {
          expectAccepted(observations[0])
          expectAccepted(observations[1])
          expect(logs).to.deep.equal([
            [ reportLine("A spec step results in extra animation frame tasks!"),
            reportLine("See the documentation for Spec.Time.nextAnimationFrame for more details.")
            ]
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