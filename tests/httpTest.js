const chai = require('chai')
const expect = chai.expect
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
        expectAccepted(observations[3])
        expectRejected(observations[4], [
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
        expectAccepted(observations[1])

        expect(observations[2].report[0]).to.deep.equal(reportLine("Claim rejected for route", "GET http://fake-api.com/stuff"))
        expect(observations[2].report[1]).to.deep.equal(reportLine("List failed to match at position 1"))
        expect(observations[2].report[2]).to.deep.equal(reportLine("Claim rejected for header", "X-Awesome-Header"))
        expect(observations[2].report[3]).to.deep.equal(reportLine("Expected", "\"some-awesome-value\""))
        expect(observations[2].report[4]).to.deep.equal(reportLine("to equal", "\"some-fun-value\""))
        expect(observations[2].report[5].statement).to.equal("The request actually had these headers")
        expect(observations[2].report[5].detail).to.contain("X-Awesome-Header = some-awesome-value\nX-Fun-Header = some-fun-value")
      })
    })
  })

  context("hasBody", () => {
    it("observes the request body as expected", (done) => {
      expectSpec("HttpSpec", "hasBody", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff"),
          reportLine("List failed to match at position 1"),
          reportLine("Claim rejected for string body"),
          reportLine("Expected", "\"\""),
          reportLine("to equal", "\"some string body that it does not have\"")
        ])
        expectRejected(observations[1], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff"),
          reportLine("List failed to match at position 1"),
          reportLine("Expected to decode request body as JSON"),
          reportLine("but it has no body at all")
        ])
        expectAccepted(observations[2])
        expectRejected(observations[3], [
          reportLine("Claim rejected for route", "POST http://fake-api.com/stuff"),
          reportLine("List failed to match at position 1"),
          reportLine("Claim rejected for string body"),
          reportLine("Expected", "\"{\\\"name\\\":\\\"fun person\\\",\\\"age\\\":88}\""),
          reportLine("to equal", "\"{\\\"blah\\\":3}\"")
        ])
        expectAccepted(observations[4])
        expectRejected(observations[5], [
          reportLine("Claim rejected for route", "POST http://fake-api.com/stuff"),
          reportLine("List failed to match at position 1"),
          reportLine("Expected to decode request body as JSON", "{\"name\":\"fun person\",\"age\":88}"),
          reportLine("but the decoder failed", "Problem with the value at json.name:\n\n    \"fun person\"\n\nExpecting an INT")
        ])
      })
    })
  })

  context("queryParameter", () => {
    it("observes the query parameters as expected", (done) => {
      expectSpec("HttpSpec", "queryParams", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff?*"),
          reportLine("List failed to match at position 1"),
          reportLine("Claim rejected for query parameter", "activity"),
          reportLine("List failed to match at position 1"),
          reportLine("Expected", "\"bowling\""),
          reportLine("to equal", "\"nothing\"")
        ])
        expectRejected(observations[2], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff?*"),
          reportLine("List failed to match at position 1"),
          reportLine("Claim rejected for query parameter", "unknown"),
          reportLine("List failed to match"),
          reportLine("Expected list to have length", "1"),
          reportLine("but it has length", "0")
        ])
        expectRejected(observations[3], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff?activity=running"),
          reportLine("Expected list to have length", "1"),
          reportLine("but it has length", "0")
        ])
        expectAccepted(observations[4])
      })
    })
  })

  context("route query", () => {
    it("matches the route as expected", (done) => {
      expectSpec("HttpSpec", "routeQuery", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
        expectAccepted(observations[4])
      })
    })
  })

  context("route path", () => {
    it("matches the route as expected", (done) => {
      expectSpec("HttpSpec", "routePath", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })
})