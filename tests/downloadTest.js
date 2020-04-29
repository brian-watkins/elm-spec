const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")


describe("download files", () => {
  context("downloading a file", () => {
    it("downloads the file", (done) => {
      expectSpec("DownloadSpec", "downloadFile", done, (observations) => {
        expectAccepted(observations[0])
      })
    })

    it("prints an error when a claim fails", (done) => {
      expectSpec("DownloadSpec", "claimFailure", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded file name"),
          reportLine("Expected", "\"funFile.txt\""),
          reportLine("to equal", "\"funnyText.text\"")
        ])
        expectRejected(observations[1], [
          reportLine("Item at index 0 did not satisfy claim:"),
          reportLine("Claim rejected for downloaded file text"),
          reportLine("Expected", "\"Here is some fun text!\""),
          reportLine("to equal", "\"blah\"")
        ])
      })
    })
  })
})