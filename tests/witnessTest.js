const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("witness", () => {
  describe("log and expect", () => {
    it("runs the spec as expected", (done) => {
      expectSpec("WitnessSpec", "log", done, (observations) => {
        expectAccepted(observations[0])

        expectRejected(observations[1], [
          reportLine("Claim rejected for witness", "injected"),
          reportLine("Expected list to have length", "3"),
          reportLine("but it has length", "1")
        ])

        expectRejected(observations[2], [
          reportLine("Claim rejected for witness", "injected"),
          reportLine("Unable to decode statement recorded by witness", "Problem with the given value:\n\n72\n\nExpecting a STRING")
        ])
      })
    })    
  })
})