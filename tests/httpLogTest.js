const chai = require('chai')
const expect = chai.expect
const { expectSpec, expectAccepted, reportLine } = require("./helpers/SpecHelpers")

describe("log http requests", () => {
  it("logs the http requests", (done) => {
    expectSpec("HttpLogSpec", "logRequests", done, (observations, error, logs) => {
      expectLogReport(logs[0], [
        reportLine("No HTTP requests received")
      ])
      expectLogReport(logs[1], [
        reportLine("Received 1 HTTP request"),
        reportLine("GET http://fun.com/fun/1", "Headers: [ Content-Type = text/plain;charset=utf-8, X-Fun-Header = my-header ]\nEmpty Body")
      ])
      expectLogReport(logs[2], [
        reportLine("Received 2 HTTP requests"),
        reportLine("GET http://fun.com/fun/1", "Headers: [ Content-Type = text/plain;charset=utf-8, X-Fun-Header = my-header ]\nEmpty Body"),
        reportLine("GET http://awesome.com/awesome?name=cool", "Headers: [ Content-Type = text/plain;charset=utf-8 ]\nEmpty Body")
      ])
      expectLogReport(logs[3], [
        reportLine("Received 3 HTTP requests"),
        reportLine("GET http://fun.com/fun/1", "Headers: [ Content-Type = text/plain;charset=utf-8, X-Fun-Header = my-header ]\nEmpty Body"),
        reportLine("GET http://awesome.com/awesome?name=cool", "Headers: [ Content-Type = text/plain;charset=utf-8 ]\nEmpty Body"),
        reportLine("POST http://super.com/super", "Headers: [ Content-Type = text/plain;charset=utf-8, X-Fun-Header = my-header, X-Super-Header = super ]\nBody: {\"name\":\"Cool Dude\",\"count\":27}")
      ])

      expectAccepted(observations[0])
      expectAccepted(observations[1])
    })
  }) 
})

const expectLogReport = (actual, expected) => {
  expect(actual).to.deep.equal(expected)
}