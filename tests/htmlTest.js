const chai = require('chai')
const expect = chai.expect
const { runBrowserTestSpec } = require("./helpers/SpecHelpers")

describe("html plugin", () => {
  context("when there is a single observation", () => {
    it("renders the view as necessary for the spec", (done) => {
      runBrowserTestSpec("HtmlSpec", "single", done, (observations) => {
        expect(observations).to.have.length(1)
        expect(observations[0].summary).to.equal("ACCEPT")
      })
    })
  })

  context("when there are multiple distinct (deferred) observations about the html", () => {
    it("handles selecting the appropriate element for each observation", (done) => {
      runBrowserTestSpec("HtmlSpec", "multiple", done, (observations) => {
        expect(observations).to.have.length(2)
        expect(observations[0].summary).to.equal("ACCEPT")
        expect(observations[1].summary).to.equal("ACCEPT")
      })
    })  
  })

  context("hasText", () => {
    it("prints the proper error message", (done) => {
      runBrowserTestSpec("HtmlSpec", "hasTextFails", done, (observations) => {
        expect(observations[0].summary).to.equal("REJECT")
        expect(observations[0].message).to.equal("Expected text\n\tSomething not present\nbut the actual text was\n\tHello, Cool Dude!")
      })
    })
  })
})