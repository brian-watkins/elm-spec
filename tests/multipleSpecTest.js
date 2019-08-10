const chai = require('chai')
const expect = chai.expect
const { compile, runSpec } = require("./helpers/SpecHelpers")

describe("multiple specs", () => {
  it("runs all the provided specs", (done) => {
    compile().then((Elm) => {
      var app = Elm.Specs.MultipleSpecSpec.init()
  
      runSpec(app, done, (observations) => {
        expect(observations).to.have.length(4)
      })
    }).catch((err) => {
      console.error(err)
      process.exit(1)
    })
  })
})