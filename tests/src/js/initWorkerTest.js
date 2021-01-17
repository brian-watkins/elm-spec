const { expectPassingSpec } = require('./helpers/SpecHelpers')

describe("Init Worker", () => {
  
  describe("When the worker program is used and init is called", () => {
    it("updates the model to that provided by the init function", (done) => {
      expectPassingSpec("InitWorkerSpec", "modelNoCommandInit", done)
    })

    it("runs the command provided by the init function", (done) => {
      expectPassingSpec("InitWorkerSpec", "modelAndCommandInit", done)
    })
  })

})

