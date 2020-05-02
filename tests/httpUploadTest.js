const chai = require('chai')
const expect = chai.expect
const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("http upload", () => {
  context("uploading a file", () => {
    it("uploads the file", (done) => {
      expectSpec("HttpUploadSpec", "uploadFile", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        
        expect(observations[2].summary).to.equal("REJECT")
        expect(observations[2].report[2].statement).to.equal("Claim rejected for file body")
        expect(observations[2].report[3].statement).to.equal("Expected")
        expect(observations[2].report[4].statement).to.equal("to contain 1 instance of")

        expectRejected(observations[3], [
          reportLine("Claim rejected for route", "POST http://fake-api.com/files"),
          reportLine("List failed to match at position 1"),
          reportLine("Claim rejected for string body", "The request body is a file.")
        ])
        expectRejected(observations[4], [
          reportLine("Claim rejected for route", "POST http://fake-api.com/files"),
          reportLine("List failed to match at position 1"),
          reportLine("Claim rejected for json body", "The request body is a file.")
        ])
      })
    })
  })
})