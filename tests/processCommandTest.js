const { expectPassingSpec } = require('./helpers/SpecHelpers')

describe("process commands", () => {
  describe("when the update function triggers a command", () => {
    it("processes commands as expected until there are no more", (done) => {
      expectPassingSpec("ProcessCommandSpec", "processCommand", done)
    })
  })

  describe("when the program executes terminating commands batched with non-terminating", () => {
    it("proceeds to the next step only after all commands have been processed", (done) => {
      expectPassingSpec("ProcessCommandSpec", "terminatingAndNonTerminating", done)
    })
  })
})