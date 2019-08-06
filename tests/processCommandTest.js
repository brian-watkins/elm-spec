const { Elm } = require('./specs.js')
const { expectPassingSpec } = require('./helpers/SpecHelpers')

describe("process commands", () => {
  describe("when the update function triggers a command", () => {
    it("processes commands as expected until there are no more", (done) => {
      expectPassingSpec(Elm.Specs.ProcessCommandSpec, "", done)
    })
  })
})