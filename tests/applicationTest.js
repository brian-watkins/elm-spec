const {
  htmlContext,
  runSpec,
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
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
    context("when no url change handler is set", () => {
      it("fails the test", (done) => {
        expectSpec("ApplicationSpec", "noChangeUrlHandler", done, (observations) => {
          expectRejected(observations[0], [
            reportLine("A URL change occurred, but no handler has been provided."),
            reportLine("Use Spec.Subject.onUrlChange to set a handler.")
          ])  
        })
      })
    })

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
    it("fails the test", (done) => {
      expectSpec("ApplicationSpec", "noRequestHandler", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("A URL request occurred, but no handler has been provided."),
          reportLine("Use Spec.Subject.onUrlRequest to set a handler.")
        ])
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
      htmlContext.evaluate((Elm) => {
        var app = Elm.Specs.NoKeySpec.init()

        runSpec(app, htmlContext, {}, done, (observations) => {
          expectRejected(observations[0], [
            reportLine("Subject.initForApplication requires a Browser.Navigation.Key! Make sure to use Spec.browserProgram to run specs for Browser applications!")
          ])
        })
      })
    })
  })
})