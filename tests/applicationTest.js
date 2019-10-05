const { expectBrowserSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("application", () => {
  context("when the url is changed", () => {
    context("when no url change handler is set", () => {
      it("fails the test", (done) => {
        expectBrowserSpec("ApplicationSpec", "noChangeUrlHandler", done, (observations) => {
          expectRejected(observations[0], [
            reportLine("A URL change occurred, but no handler has been provided."),
            reportLine("Use Spec.Subject.onUrlChange to set a handler.")
          ])  
        })
      })
    })
    context("when the change handler is set", () => {
      it("acts as expected", (done) => {
        expectBrowserSpec("ApplicationSpec", "changeUrl", done, (observations) => {
          expectAccepted(observations[0])
          expectAccepted(observations[1])
          expectAccepted(observations[2])
        })
      })
    })
  })
})