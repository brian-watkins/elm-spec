const {
  expectSpec,
  expectAccepted,
  isForRealBrowser
} = require("./helpers/SpecHelpers")
const {
  expectRejectedWhenDocumentTargeted,
  expectRejectedWhenNoElementTargeted
} = require("./helpers/eventTestHelpers")

describe("dom functions", () => {
  context("viewport", () => {
    it("sets and gets the viewport as expected", (done) => {
      expectSpec("HtmlViewportSpec", "viewport", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })

  context("observeBrowserViewport", () => {
    it("observes the browser viewport as expected", (done) => {
      expectSpec("HtmlViewportSpec", "observeBrowserViewport", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
      })
    })
  })

  context("setElementViewport", () => {
    it("sets the element viewport as expected", (done) => {
      expectSpec("HtmlViewportSpec", "setElementViewport", done, (observations) => {
        expectAccepted(observations[0])
        expectRejectedWhenNoElementTargeted("setElementViewport", observations[1])
        expectRejectedWhenDocumentTargeted("setElementViewport", observations[2])
      })
    })
  })

  if (isForRealBrowser()) {
    context("element position", () => {
      it("finds the absolute element position even when the viewport changes", (done) => {
        expectSpec("HtmlViewportSpec", "elementPosition", done, (observations) => {
          expectAccepted(observations[0])
          expectAccepted(observations[1])
          expectAccepted(observations[2])
          expectAccepted(observations[3])
          expectAccepted(observations[4])
        })
      })
    })  
  } else {
    context("element in jsdom", () => {
      it("just returns zero for the element position", (done) => {
        expectSpec("HtmlViewportSpec", "jsdomElement", done, (observations) => {
          expectAccepted(observations[0])
        })
      })
    })
  }
})