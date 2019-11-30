const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe('HTTP', () => {
  context("HTTP GET", () => {
    it("handles an HTTP GET as expected", (done) => {
      expectSpec("HttpSpec", "get", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
      })
    })
  })

  context("expectRequest", () => {
    it("counts the number of requests as expected", (done) => {
      expectSpec("HttpSpec", "expectRequest", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectRejected(observations[3], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff"),
          reportLine("Expected list to have length", "17"),
          reportLine("but it has length", "3")
        ])
      })
    })
  })

  context("abstain from responding", () => {
    it("abstains from responding as expected", (done) => {
      expectSpec("HttpSpec", "abstain", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })

  context("stub error", () => {
    it("returns an error for the request", (done) => {
      expectSpec("HttpSpec", "error", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })

  context("stub headers", () => {
    it("response with the expected headers", (done) => {
      expectSpec("HttpSpec", "header", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("hasHeader", () => {
    it("observes request headers as expected", (done) => {
      expectSpec("HttpSpec", "hasHeader", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff"),
          reportLine("Expected request to have header", "X-Missing-Header = some-fun-value"),
          reportLine("but it has", "Content-Type = text/plain;charset=utf-8\nX-Awesome-Header = some-awesome-value\nX-Fun-Header = some-fun-value")
        ])
        expectRejected(observations[2], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff"),
          reportLine("Expected request to have header", "X-Awesome-Header = some-fun-value"),
          reportLine("but it has", "Content-Type = text/plain;charset=utf-8\nX-Awesome-Header = some-awesome-value\nX-Fun-Header = some-fun-value")
        ])
      })
    })
  })

  context("hasBody", () => {
    it("observes the request body as expected", (done) => {
      expectSpec("HttpSpec", "hasBody", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Claim rejected for route", "POST http://fake-api.com/stuff"),
          reportLine("List failed to match at position 1"),
          reportLine("Expected request to have body with string", "{\"blah\":3}"),
          reportLine("but it has", "{\"name\":\"fun person\",\"age\":88}")
        ])
        expectAccepted(observations[2])
        expectRejected(observations[3], [
          reportLine("Claim rejected for route", "POST http://fake-api.com/stuff"),
          reportLine("List failed to match at position 1"),
          reportLine("Expected to decode request body as JSON", "{\"name\":\"fun person\",\"age\":88}"),
          reportLine("but the decoder failed", "Problem with the value at json.name:\n\n    \"fun person\"\n\nExpecting an INT")
        ])
      })
    })
  })
})