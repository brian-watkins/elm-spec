const { Elm } = require('./specs.js')
const { expectPassingSpec } = require('./helpers/SpecHelpers')

describe("port commands", () => {
  describe("when port commands are observed", () => {
    describe("when a message is sent out via the expected port", () => {
      it("records the message sent", (done) => {
        expectPassingSpec(Elm.Specs.PortCommandSpec, "", done)
      })
    })
  })
})