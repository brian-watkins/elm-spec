const { expectSpec, expectAccepted } = require("./helpers/SpecHelpers")

describe("html subscription", () => {
  it("updates the view when the subscription is received", (done) => {
    expectSpec("HtmlSubscriptionSpec", "send", done, (observations) => {
      expectAccepted(observations[0])
    })
  })
})