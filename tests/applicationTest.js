const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine,
  expectProgram
} = require("./helpers/SpecHelpers")

describe("application", () => {
  context("given a url", () => {
    it("sets the location as expected", (done) => {
      expectSpec("ApplicationSpec", "applyUrl", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })
  context("when the url is changed", () => {
    context("when the change handler is set", () => {
      it("acts as expected", (done) => {
        expectSpec("ApplicationSpec", "changeUrl", done, (observations) => {
          expectAccepted(observations[0])
          expectAccepted(observations[1])
          expectAccepted(observations[2])
          expectAccepted(observations[3])
        })
      })
    })
  })

  context("document title", () => {
    it("observes the title as expected", (done) => {
      expectSpec("ApplicationSpec", "changeTitle", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })

  context("when no url request handler is set", () => {
    it("fails the test if initForApplication is used", (done) => {
      expectSpec("ApplicationSpec", "noNavigationConfig", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("A URL request occurred for an application, but no handler has been provided."),
          reportLine("Use Spec.Setup.forNavigation to set a handler.")
        ])
        expectRejected(observations[1], [
          reportLine("A URL change occurred for an application, but no handler has been provided."),
          reportLine("Use Spec.Setup.forNavigation to set a handler.")
        ])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
        expectAccepted(observations[4])
        expectAccepted(observations[5])
      })
    })
  })

  context("click a link", () => {
    it("handles clicked links as expected", (done) => {
      expectSpec("ApplicationSpec", "clickLink", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
      })
    })
  })

  context("when do not use Spec.browserProgram to run the spec", () => {
    it("fails with a message", (done) => {
      expectProgram("NoKeySpec", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("Spec.Setup.initForApplication requires a Browser.Navigation.Key! Make sure to use Spec.Runner.browserProgram to run specs for Browser applications!")
        ])
      })
    })
  })
})