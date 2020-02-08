const {
  expectSpec,
  expectAccepted,
} = require("./helpers/SpecHelpers")
const {
  expectRejectedWhenDocumentTargeted,
  expectRejectedWhenNoElementTargeted
} = require("./helpers/eventTestHelpers")

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

  context("setElementViewport", () => {
    it("sets the element viewport as expected", (done) => {
      expectSpec("DomSpec", "setElementViewport", done, (observations) => {
        expectAccepted(observations[0])
        expectRejectedWhenNoElementTargeted("setElementViewport", observations[1])
        expectRejectedWhenDocumentTargeted("setElementViewport", observations[2])
      })
    })
  })
})