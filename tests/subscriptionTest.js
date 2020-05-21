const chai = require('chai')
const expect = chai.expect
const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require('./helpers/SpecHelpers')

describe("subscriptions", () => {
  describe("when there are port subscriptions", () => {
    context("when the subscription name refers to a registered port", () => {
      it("sends the subscription and processes the message as expected", (done) => {
        expectSpec("SubscriptionSpec", "send", done, (observations) => {
          expectAccepted(observations[0])
          expectAccepted(observations[1])
          expectRejected(observations[2], [
            reportLine("Attempt to send message to unknown subscription", "unknown-subscription")
          ])
        })
      })
    })
    context("when there are multiple subscribers for the same subscription", () => {
      it("handles all the messages as expected", (done) => {
        expectSpec("SubscriptionSpec", "multipleSubscribers", done, (observations) => {
          expectAccepted(observations[0])
          expectAccepted(observations[1])

          expect(observations[2].summary).to.equal("REJECTED")
          expect(observations[2].report[0].statement).to.equal("Unable to read file at")
        })
      })
    })
  })
})