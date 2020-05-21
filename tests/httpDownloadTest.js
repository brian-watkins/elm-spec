const chai = require('chai')
const expect = chai.expect
const {
  expectSpec,
  expectAccepted
} = require("./helpers/SpecHelpers")

describe("HTTP download", () => {
  context("stub bytes response via HTTP", () => {
    it("downloads the stubbed bytes as expected", (done) => {
      expectSpec("HttpDownloadSpec", "stubBytes", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejectedWithFileError(observations[2], "tests/src/some/bad/path.txt")
      })
    })
  
    it("stubs progress of bytes and files received", (done) => {
      expectSpec("HttpDownloadSpec", "bytesProgress", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
        expectRejectedWithFileError(observations[4], "tests/src/some/wrong/path.txt")
        expectRejectedWithFileError(observations[5], "tests/src/huh/what/file.txt")
      })
    })
  })

  context("stub HTTP response with text from file", () => {
    it("downloads the text as expected", (done) => {
      expectSpec("HttpDownloadSpec", "stubText", done, (observations) => {
        expectAccepted(observations[0])
        expectRejectedWithFileError(observations[1], "tests/src/some/nonExisting/file.txt")
      })
    })
  })
})

const expectRejectedWithFileError = (observation, path) => {
  expect(observation.summary).to.equal("REJECTED")
  expect(observation.report[0].statement).to.equal("Unable to read file at")
  expect(observation.report[0].detail).to.contain(path)
}