const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("multipart http request", () => {
  it("makes a multipart file request", (done) => {
    expectSpec("HttpMultipartSpec", "multipart", done, (observations) => {
      expectAccepted(observations[0])
      expectAccepted(observations[1])
      expectAccepted(observations[2])
      expectAccepted(observations[3])
      expectRejected(observations[4], [
        reportLine("Claim rejected for route", "POST http://fake.com/api/files"),
        reportLine("Item at index 0 did not satisfy claim:"),
        reportLine("Claim rejected for body part: bad-name"),
        reportLine("List failed to match"),
        reportLine("Expected list to have length", "1"),
        reportLine("but it has length", "0")
      ])
      expectRejected(observations[5], [
        reportLine("Claim rejected for route", "POST http://fake.com/api/files"),
        reportLine("Item at index 0 did not satisfy claim:"),
        reportLine("Claim rejected for request body", "The request has a multipart body.\nUse Spec.Http.bodyPart to make a claim about the request body.")
      ])
    })
  })
})