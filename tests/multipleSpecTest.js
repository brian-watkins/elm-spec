const chai = require('chai')
const expect = chai.expect
const { globalContext, runSpec } = require("./helpers/SpecHelpers")

describe("multiple specs", () => {
  it("runs all the provided specs", (done) => {
    globalContext.evaluate((Elm) => {
      var app = Elm.Specs.MultipleSpecSpec.init()
  
      runSpec(app, globalContext, {}, done, (observations) => {
        expect(observations).to.have.length(4)
      })
    })
  })
})