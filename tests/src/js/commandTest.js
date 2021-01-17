const { expectPassingSpec } = require("./helpers/SpecHelpers")

describe("command plugin", () => {
  describe("when commands are sent during the spec", () => {
    it("processes the commands as expected", (done) => {
      expectPassingSpec("CommandSpec", "", done)
    })
  })
})