const { expectPassingSpec } = require('./helpers/SpecHelpers')

describe("port commands", () => {
  describe("when port commands are observed", () => {
    describe("when a message is sent out via the expected port", () => {
      it("records the message sent", (done) => {
        expectPassingSpec("PortCommandSpec", "one", done)
      })
    })

    describe("when multiple messages are sent out via the expected port", () => {
      it("records all the messages sent", (done) => {
        expectPassingSpec("PortCommandSpec", "many", done)
      })
    })
  })
})