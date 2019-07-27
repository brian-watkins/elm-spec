const chai = require('chai')
const expect = chai.expect
const { Elm } = require('./specs.js')

describe("Init Worker", () => {
  
  describe("When the worker program is used and init is called", () => {
    it("updates the model to that provided by the init function", (done) => {
      var app = Elm.Specs.InitWorkerSpec.init({
        flags: { specName: "modelNoCommandInit" }
      })

      app.ports.sendOut.subscribe((specMessage) => {
        expect(specMessage.home).to.equal("spec-observation")
        const observation = specMessage.body
        expect(observation.summary).to.equal("ACCEPT")
        done()
      })
    })

    it("runs the command provided by the init function", (done) => {
      var app = Elm.Specs.InitWorkerSpec.init({
        flags: { specName: "modelAndCommandInit" }
      })

      app.ports.sendOut.subscribe((specMessage) => {
        expect(specMessage.home).to.equal("spec-observation")
        const observation = specMessage.body
        expect(observation.summary).to.equal("ACCEPT")
        done()
      })
    })
  })

})

