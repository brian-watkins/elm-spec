const { expectSpec, expectAccepted } = require("./helpers/SpecHelpers")

describe("stub bytes response via HTTP", () => {
  it("downloads the stubbed bytes as expected", (done) => {
    expectSpec("HttpDownloadSpec", "stubBytes", done, (observations) => {
      expectAccepted(observations[0])
    })
  })

  it("stubs progress of bytes received", (done) => {
    expectSpec("HttpDownloadSpec", "bytesProgress", done, (observations) => {
      expectAccepted(observations[0])
      expectAccepted(observations[1])
    })
  })
})