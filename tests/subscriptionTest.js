const { expectSpec, expectAccepted, expectRejected, reportLine } = require('./helpers/SpecHelpers')

describe("subscriptions", () => {
  describe("when there are port subscriptions", () => {
    describe("when the subscription name refers to a registered port", () => {
      it("sends the subscription and processes the message as expected", (done) => {
        expectSpec("SubscriptionSpec", "", done, (observations) => {
          expectAccepted(observations[0])
          expectAccepted(observations[1])
          expectRejected(observations[2], [
            reportLine("Attempt to send message to unknown subscription", "unknown-subscription")
          ])
        })
      })
    })
  })
})