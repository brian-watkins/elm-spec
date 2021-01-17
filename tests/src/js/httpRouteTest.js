const chai = require('chai')
const expect = chai.expect
const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("Http Route", () => {
  context("regex", () => {
    it("uses a regex to match requests as expected", (done) => {
      expectSpec("HttpRouteSpec", "regex", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
        expectRejected(observations[4], [
          reportLine("Claim rejected for route", "GET /http:\\/\\/fake\\-api\\.com\\/awesome\\?.*/"),
          reportLine("Expected list to have length", "1"),
          reportLine("but it has length", "0")
        ])
      })
    })
    context("when the regex cannot compile", () => {
      it("aborts the scenario", (done) => {
        expectSpec("HttpRouteSpec", "badRegex", done, (observations) => {
          expectRejected(observations[0], [
            reportLine("Unable to parse regular expression used to observe requests", "/[A--Z]/")
          ])
          expect(observations[0].conditions).to.deep.equal([
            "bad regex",
            "Scenario: the regex in an observer doesn't compile",
            "When an http request is triggered",
            "It observes the request"
          ])
          expect(observations[0].description).to.equal("Unable to complete observation")
          
          expectRejected(observations[1], [
            reportLine("Unable to parse regular expression for stubbed route", "/[1/")
          ])
          expect(observations[1].conditions).to.deep.equal([
            "bad regex",
            "Scenario: the regex in a stub doesn't compile and there are no steps",
          ])
          expect(observations[1].description).to.equal("Unable to configure scenario")

          expectRejected(observations[2], [
            reportLine("Unable to parse regular expression for stubbed route", "/[2/")
          ])
          expect(observations[2].conditions).to.deep.equal([
            "bad regex",
            "Scenario: the regex in a stub doesn't compile and there are steps",
          ])
          expect(observations[2].description).to.equal("Unable to configure scenario")
        })
      })
    })
  })

  context("url claims", () => {
    it("handles claims about the request url as expected", (done) => {
      expectSpec("HttpRouteSpec", "url", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Claim rejected for route", "GET /fake\\.com\\/fun/"),
          reportLine("List failed to match at position 1"),
          reportLine("Expected", "http://fake.com/fun?sport=cross-country%20skiing"),
          reportLine("to contain 1 instance of", "sport=cycling"),
          reportLine("but the text was found 0 times")
        ])
      })
    })
  })
})