const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("multipart http request", () => {
  it("makes a multipart file request", (done) => {
    expectSpec("HttpMultipartSpec", "multipart", done, (observations) => {
      expectAccepted(observations[0])
      expectAccepted(observations[1])
      expectAccepted(observations[2])
      expectAccepted(observations[3])
      expectAccepted(observations[4])
      expectRejected(observations[5], [
        reportLine("Claim rejected for route", "POST http://fake.com/api/files"),
        reportLine("Item at index 0 did not satisfy claim:"),
        reportLine("Claim rejected for text data in body part: my-name"),
        reportLine("List failed to match at position 1"),
        reportLine("Actual", "\"Cool Dude\""),
        reportLine("does not equal expected", "\"Awesome Person\"")
      ])
      expectRejected(observations[6], [
        reportLine("Claim rejected for route", "POST http://fake.com/api/files"),
        reportLine("Item at index 0 did not satisfy claim:"),
        reportLine("Claim rejected for file data in body part: my-name", "The request data is text.")
      ])
      expectRejected(observations[7], [
        reportLine("Claim rejected for route", "POST http://fake.com/api/files"),
        reportLine("Item at index 0 did not satisfy claim:"),
        reportLine("Claim rejected for text data in body part: bad-name"),
        reportLine("List failed to match"),
        reportLine("Expected list to have length", "1"),
        reportLine("but it has length", "0")
      ])
      expectRejected(observations[8], [
        reportLine("Claim rejected for route", "POST http://fake.com/api/files"),
        reportLine("Item at index 0 did not satisfy claim:"),
        reportLine("Claim rejected for request body", "The request has a multipart body.\nUse Spec.Http.bodyPart to make a claim about the request body.")
      ])
    })
  })
})