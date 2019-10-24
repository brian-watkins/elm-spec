const {
  expectPassingSpec,
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require('./helpers/SpecHelpers')

describe("port commands", () => {
  describe("when port commands are observed", () => {
    describe("when a message is sent out via the expected port", () => {
      it("records the message sent", (done) => {
        expectSpec("PortCommandSpec", "one", done, (observations) => {
          expectAccepted(observations[0])
          expectRejected(observations[1], [
            reportLine("Claim rejected for port", "some-other-port"),
            reportLine("Expected", "[]"),
            reportLine("to equal", "[\"Unknown!\"]")
          ])
        })
      })
    })

    describe("when multiple messages are sent out via the expected port", () => {
      it("records all the messages sent", (done) => {
        expectPassingSpec("PortCommandSpec", "many", done)
      })
    })
  })
})