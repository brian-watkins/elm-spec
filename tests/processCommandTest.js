const { Elm } = require('./specs.js')
const { expectPassingSpec } = require('./helpers/SpecHelpers')

describe("process commands", () => {
  describe("when the update function triggers a command", () => {
    it("processes the command as expected", (done) => {
      expectPassingSpec(Elm.Specs.ProcessCommandSpec, "", done)
    })
  })
})