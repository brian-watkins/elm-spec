const chai = require('chai')
const expect = chai.expect
const {
  expectAccepted,
  expectSpec,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("file selection", () => {
  context("selecting a file", () => {
    it("selects files as expected", (done) => {
      expectSpec("SelectFileSpec", "selectFile", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
        expectAccepted(observations[4])
        expectAccepted(observations[5])
        expectAccepted(observations[6])
        expectAccepted(observations[7])
      })
    })

    it("sets the last modified time as expected", (done) => {
      expectSpec("SelectFileSpec", "lastModified", done, (observations) => {
        expectAccepted(observations[0])
      })
    })

    it("sets the mime type as expected", (done) => {
      expectSpec("SelectFileSpec", "mimeType", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("no file selector open", () => {
    it("reports an error", (done) => {
      expectSpec("SelectFileSpec", "noOpenSelector", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("No open file selector!", "Either click an input element of type file or otherwise take action so that a File.Select.file(s) command is sent by the program under test.")
        ])
      })
    })
  })

  context("no file is selected", () => {
    it("resets the file selector between scenarios", (done) => {
      expectSpec("SelectFileSpec", "noFileSelected", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("No open file selector!", "Either click an input element of type file or otherwise take action so that a File.Select.file(s) command is sent by the program under test.")
        ])
      })
    })
  })

  context("bad file selected to upload", () => {
    it("reports an error", (done) => {
      expectSpec("SelectFileSpec", "badFile", done, (observations) => {
        expect(observations[0].summary).to.equal("REJECT")
        expect(observations[0].report[0].statement).to.equal("Unable to read file at")
        expect(observations[0].report[0].detail).to.contain("tests/src/non-existent-file.txt")
      })
    })
  })
})