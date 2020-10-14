const {
  expectSpec,
  expectAccepted,
} = require('./helpers/SpecHelpers')

describe("update view", () => {
  context("when the subscription triggers a view update", () => {
    it("updates the view as expected", (done) => {
      expectSpec("UpdateViewSpec", "fromPort", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })
})