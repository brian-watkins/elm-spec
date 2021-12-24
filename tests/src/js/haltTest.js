const {
  expectSpec,
  reportLine,
  expectRejected
} = require("./helpers/SpecHelpers")

describe("halt command", () => {
  it("halts the scenario", (done) => {
    expectSpec("HaltSpec", "haltScenario", done, (observations) => {
      expectRejected(observations[0], [
        reportLine("You told me to stop!!?")
      ])
    })
  })
})