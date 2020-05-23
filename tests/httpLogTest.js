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
        reportLine("GET http://fun.com/fun/1", "Headers: [ content-type = text/plain;charset=utf-8, x-fun-header = my-header ]\nEmpty Body")
      ])
      expectLogReport(logs[2], [
        reportLine("Received 2 HTTP requests"),
        reportLine("GET http://fun.com/fun/1", "Headers: [ content-type = text/plain;charset=utf-8, x-fun-header = my-header ]\nEmpty Body"),
        reportLine("GET http://awesome.com/awesome?name=cool", "Headers: [ content-type = text/plain;charset=utf-8 ]\nEmpty Body")
      ])
      expectLogReport(logs[3], [
        reportLine("Received 3 HTTP requests"),
        reportLine("GET http://fun.com/fun/1", "Headers: [ content-type = text/plain;charset=utf-8, x-fun-header = my-header ]\nEmpty Body"),
        reportLine("GET http://awesome.com/awesome?name=cool", "Headers: [ content-type = text/plain;charset=utf-8 ]\nEmpty Body"),
        reportLine("POST http://super.com/super", "Headers: [ content-type = text/plain;charset=utf-8, application/json, x-fun-header = my-header, x-super-header = super ]\nText data: {\"name\":\"Cool Dude\",\"count\":27}")
      ])

      expectAccepted(observations[0])
      expectAccepted(observations[1])
    })
  })

  it("logs the request with bytes", (done) => {
    expectSpec("HttpLogSpec", "logBytesRequest", done, (observations, error, logs) => {
      expectLogReport(logs[0], [
        reportLine("Received 1 HTTP request"),
        reportLine("POST http://fun.com/bytes", "Headers: [ content-type = application/octet-stream ]\nBytes data with 21 bytes")
      ])
    })
  })

  it("logs the request with a file", (done) => {
    expectSpec("HttpLogSpec", "logFileRequest", done, (observations, error, logs) => {
      expect(logs[0][0].statement).to.equal("Received 1 HTTP request")
      expect(logs[0][1].statement).to.equal("POST http://fun.com/files")
      const details = logs[0][1].detail.split("\n")
      expect(details[0]).to.equal("Headers: [ content-type = text/plain ]")
      expect(details[1].replace(/:/g, "/")).to.contain("/some/path/to/my-test-file.txt")
    })
  })

  it("logs the multipart request", (done) => {
    expectSpec("HttpLogSpec", "logMultipartRequest", done, (observations, error, logs) => {
      expect(logs[0][0].statement).to.equal("Received 1 HTTP request")
      expect(logs[0][1].statement).to.equal("POST http://place.com/api/request")
      const details = logs[0][1].detail.split("\n")
      expect(details[0]).to.equal("Headers: [  ]")
      expect(details[1]).to.equal("Multipart request with parts:")
      expect(details[2]).to.equal("username ==> Text data: someone-cool")
      expect(details[3].replace(/:/g, "/")).to.equal("fun-image ==> File data with name/ /some/path/to/my-awesome-image.png")
      expect(details[4]).to.equal("fun-bytes ==> Bytes data with 21 bytes")
    })
  })
})

const expectLogReport = (actual, expected) => {
  expect(actual).to.deep.equal(expected)
}