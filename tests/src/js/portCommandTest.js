const { expect } = require('chai')
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

  describe("when port messages are used during a step", () => {
    it("handles the step as expected", (done) => {
      expectSpec("PortCommandSpec", "observe", done, (observations) => {
        expectRejected(observations[0], [
          reportLine("Unable to respond to messages received from port", "sendTestMessageOut"),
          reportLine("No new messages have been sent via that port")
        ])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectRejected(observations[3], [
          reportLine("An error occurred responding to messages from port", "sendTestMessageOut"),
          reportLine("Unable to decode value sent through port", "Problem with the given value:\n\n\"One\"\n\nExpecting an INT")
        ])
        expect(observations.length).to.equal(4)
      })
    })
  })
})