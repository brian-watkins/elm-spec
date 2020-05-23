const chai = require('chai')
const expect = chai.expect
const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("http upload", () => {
  it("uploads a file", (done) => {
    expectSpec("HttpUploadSpec", "uploadFile", done, (observations) => {
      expectAccepted(observations[0])
      expectAccepted(observations[1])
      expectAccepted(observations[2])
      
      expect(observations[3].summary).to.equal("REJECTED")
      expect(observations[3].report[2].statement).to.equal("Claim rejected for file data")
      expect(observations[3].report[3].statement).to.equal("Expected")
      expect(observations[3].report[4].statement).to.equal("to contain 1 instance of")

      expectRejected(observations[4], [
        reportLine("Claim rejected for route", "POST http://fake-api.com/files"),
        reportLine("List failed to match at position 1"),
        reportLine("Claim rejected for text data", "The request data is a file.")
      ])
      expectRejected(observations[5], [
        reportLine("Claim rejected for route", "POST http://fake-api.com/files"),
        reportLine("List failed to match at position 1"),
        reportLine("Claim rejected for JSON data", "The request data is a file.")
      ])
      expectRejected(observations[6], [
        reportLine("Claim rejected for route", "POST http://fake-api.com/files"),
        reportLine("List failed to match at position 1"),
        reportLine("Claim rejected for bytes data", "The request data is a file.")
      ])

      expectAccepted(observations[7])
    })
  })

  it("uploads bytes", (done) => {
    expectSpec("HttpUploadSpec", "uploadBytes", done, (observations) => {
      expectAccepted(observations[0])
      expectAccepted(observations[1])
      
      expect(observations[2].summary).to.equal("REJECTED")
      expect(observations[2].report[2].statement).to.equal("Claim rejected for bytes data")
      expect(observations[2].report[3].statement).to.equal("Expected")
      expect(observations[2].report[4].statement).to.equal("to equal")

      expectRejected(observations[3], [
        reportLine("Claim rejected for route", "POST http://fake-api.com/files"),
        reportLine("List failed to match at position 1"),
        reportLine("Claim rejected for file data", "The request data is binary. Use Spec.Http.bytesData instead.")
      ])
      expectRejected(observations[4], [
        reportLine("Claim rejected for route", "POST http://fake-api.com/files"),
        reportLine("List failed to match at position 1"),
        reportLine("Claim rejected for text data", "The request data is binary. Use Spec.Http.bytesData instead.")
      ])
      expectRejected(observations[5], [
        reportLine("Claim rejected for route", "POST http://fake-api.com/files"),
        reportLine("List failed to match at position 1"),
        reportLine("Claim rejected for JSON data", "The request data is binary. Use Spec.Http.bytesData instead.")
      ])
    })
  })

  it("reports on progress", (done) => {
    expectSpec("HttpUploadSpec", "progress", done, (observations) => {
      expectAccepted(observations[0])
      expectAccepted(observations[1])
      expectAccepted(observations[2])
      expectAccepted(observations[3])
      expectAccepted(observations[4])
    })
  })
})