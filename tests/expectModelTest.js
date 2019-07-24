const chai = require('chai')
const expect = chai.expect
const { Elm } = require('./specs.js')

describe("Expect Model", () => {
  
  describe("When the spec is not observed to be valid", () => {
    it("sends a failure message", (done) => {
      var app = Elm.Specs.ExpectModelSpec.init({
        flags: { specName: "failing" }
      })

      app.ports.sendOut.subscribe((specMessage) => {
        expect(specMessage.home).to.equal("spec-observation")
        const observation = specMessage.body
        expect(observation.summary).to.equal("REJECT")
        expect(observation.message).to.equal("Expected 17 to equal 99, but it does not.")
        done()
      })
    })
  })

  describe("When the spec is observed to be valid", () => {
    it("sends a success message", (done) => {
      var app = Elm.Specs.ExpectModelSpec.init({
        flags: { specName: "passing" }
      })

      app.ports.sendOut.subscribe((specMessage) => {
        expect(specMessage.home).to.equal("spec-observation")
        const observation = specMessage.body
        expect(observation.summary).to.equal("ACCEPT")
        expect(observation.message).to.be.null
        done()
      })
    })
  })

})