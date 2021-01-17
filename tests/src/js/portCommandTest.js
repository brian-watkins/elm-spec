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
          expectAccepted(observations[1])
          expectAccepted(observations[2])

          expectRejected(observations[3], [
            reportLine("Claim rejected for port", "some-other-port"),
            reportLine("Actual", "[]"),
            reportLine("does not equal expected", "[\"Unknown!\"]")
          ])

          expectRejected(observations[4], [
            reportLine("Claim rejected for port", "sendTestMessageOut"),
            reportLine("Unable to decode value sent through port", "Problem with the given value:\n\n\"From init!\"\n\nExpecting an INT")
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