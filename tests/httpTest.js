const { expectBrowserSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe('HTTP', () => {
  context("HTTP GET", () => {
    it("handles an HTTP GET as expected", (done) => {
      expectBrowserSpec("HttpSpec", "get", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })

  context("expectRequest", () => {
    it("counts the number of requests as expected", (done) => {
      expectBrowserSpec("HttpSpec", "expectRequest", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectRejected(observations[3], [
          reportLine("Observation rejected for route", "GET http://fake-api.com/stuff"),
          reportLine("Expected list to have length", "17"),
          reportLine("but it has length", "1")
        ])
      })
    })
  })
})