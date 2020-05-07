const { expectSpec, expectAccepted } = require("./helpers/SpecHelpers")

describe("programs", () => {
  context("wrapped program", () => {
    it("handles commands from the wrapped program as expected", (done) => {
      expectSpec("ProgramSpec", "wrappedProgram", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })
})