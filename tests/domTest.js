const { expectSpec, expectAccepted } = require("./helpers/SpecHelpers")

describe("dom functions", () => {
  context("viewport", () => {
    it("sets and gets the viewport as expected", (done) => {
      expectSpec("DomSpec", "viewport", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })

  context("observeBrowserViewport", () => {
    it("observes the browser viewport as expected", (done) => {
      expectSpec("DomSpec", "observeBrowserViewport", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
      })
    })
  })
})