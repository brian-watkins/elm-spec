const { expectPassingSpec } = require('./helpers/SpecHelpers')

describe("subscriptions", () => {
  describe("when there are port subscriptions", () => {
    describe("when the subscription name refers to a registered port", () => {
      it("sends the subscription and processes the message as expected", (done) => {
        expectPassingSpec("SubscriptionSpec", "", done)
      })
    })
  })
})