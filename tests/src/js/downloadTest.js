const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")


describe("download", () => {
  context("downloading a file", () => {
    it("downloads text content", (done) => {
      expectSpec("DownloadSpec", "downloadText", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })

    it("downloads binary content", (done) => {
      expectSpec("DownloadSpec", "downloadBytes", done, (observations) => {
        expectAccepted(observations[0])
      })
    })

    it("downloads a url using File.Download.url", (done) => {
      expectSpec("DownloadSpec", "downloadUrl", done, (observations) => {
        expectAccepted(observations[0])
      })
    })

    it("downloads a url using an anchor tag", (done) => {
      expectSpec("DownloadSpec", "downloadAnchor", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
      })
    })

    it("prints an error when a claim fails for a text download", (done) => {
      expectSpec("DownloadSpec", "textClaimFailure", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded file name"),
          reportLine("Actual", "\"funFile.txt\""),
          reportLine("does not equal expected", "\"funnyText.text\"")
        ])
        expectRejected(observations[1], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded text"),
          reportLine("Actual", "\"Here is some fun text!\""),
          reportLine("does not equal expected", "\"blah\"")
        ])
        expectRejected(observations[2], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded url", "The file was not downloaded from a url.")
        ])
        expectRejected(observations[3], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded text", "Unable to decode binary data as UTF-8 text.")
        ])
      })
    })

    it("prints an error when a claim fails for a binary download", (done) => {
      expectSpec("DownloadSpec", "bytesDownloadClaimFailure", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded file name"),
          reportLine("Actual", "\"binaryText.txt\""),
          reportLine("does not equal expected", "\"funnyText.text\"")
        ])
        expectRejected(observations[1], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded bytes"),
          reportLine("Actual", "\"Here is binary text!\""),
          reportLine("does not equal expected", "\"something\"")
        ])
        expectRejected(observations[2], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded url", "The file was not downloaded from a url.")
        ])
      })
    })

    it("prints an error when a claim fails for a url download", (done) => {
      expectSpec("DownloadSpec", "downloadUrlClaimFailure", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded file name"),
          reportLine("Actual", "\"superFile.txt\""),
          reportLine("does not equal expected", "\"funnyText.text\"")
        ])
        expectRejected(observations[1], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded url"),
          reportLine("Actual", "\"http://fake.com/myFile-0.txt\""),
          reportLine("does not equal expected", "\"http://wrong.com\"")
        ])
        expectRejected(observations[2], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded text", "The file was downloaded from a url, so it has no associated text.")
        ])
        expectRejected(observations[3], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded bytes", "The file was downloaded from a url, so it has no associated bytes.")
        ])
      })
    })
  })
})