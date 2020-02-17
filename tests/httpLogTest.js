const chai = require('chai')
const expect = chai.expect
const { expectSpec, expectAccepted, reportLine } = require("./helpers/SpecHelpers")

describe("log http requests", () => {
  it.only("logs the http requests", (done) => {
    expectSpec("HttpLogSpec", "logRequests", done, (observations, error, logs) => {
      expectLogReport(logs[0], [
        reportLine("HTTP requests received", "GET http://fun.com/fun/1")
      ])
      expectLogReport(logs[1], [
        reportLine("HTTP requests received", "GET http://fun.com/fun/1\nGET http://awesome.com/awesome?name=cool")
      ])
      expectLogReport(logs[2], [
        reportLine("HTTP requests received", "GET http://fun.com/fun/1\nGET http://awesome.com/awesome?name=cool\nPOST http://super.com/super")
      ])
      expectLogReport(logs[3], [
        reportLine("No HTTP requests received")
      ])

      expectAccepted(observations[0])
      expectAccepted(observations[1])
      expectAccepted(observations[2])
    })
  }) 
})

const expectLogReport = (actual, expected) => {
  expect(actual).to.deep.equal(expected)
}