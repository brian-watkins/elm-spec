const chai = require('chai')
const expect = chai.expect
const { htmlContext, runSpec } = require("./helpers/SpecHelpers")

describe("multiple specs", () => {
  it("runs all the provided specs", (done) => {
    htmlContext.evaluate((Elm) => {
      var app = Elm.Specs.MultipleSpecSpec.init()
  
      runSpec(app, htmlContext, {}, done, (observations) => {
        expect(observations).to.have.length(4)
      })
    })
  })
})