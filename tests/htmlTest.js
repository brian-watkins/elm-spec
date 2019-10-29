const chai = require('chai')
const expect = chai.expect
const { 
  expectFailingBrowserSpec,
  expectPassingBrowserSpec,
  expectBrowserSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("html plugin", () => {
  context("when a single element is selected", () => {
    it("selects an existing element", (done) => {
      expectBrowserSpec("HtmlSpec", "single", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
    it("fails when selecting an element that does not exist", (done) => {
      expectBrowserSpec("HtmlSpec", "single", done, (observations) => {
        expect(observations[1].description).to.equal("It does not find an element that is not there")
        expectRejected(observations[1], [
          reportLine("No element matches selector", "#something-not-present")
        ])
      })
    })
  })

  context("when there are multiple distinct (deferred) observations about the html", () => {
    it("handles selecting the appropriate element for each observation", (done) => {
      expectPassingBrowserSpec("HtmlSpec", "multiple", done, (observations) => {
        expect(observations).to.have.length(4)
      })
    })  
  })

  context("when the model is updated", () => {
    it("updates the view as expected", (done) => {
      expectPassingBrowserSpec("HtmlSpec", "sub", done)
    })
  })

  context("target element", () => {
    context("when the target fails to select an element", () => {
      it("fails and reports the reason and runs the next scenario", (done) => {
        expectBrowserSpec("HtmlSpec", "targetUnknown", done, (observations) => {
          expectRejected(observations[0], [
            reportLine("No match for selector", "#some-element-that-does-not-exist")
          ])
          expectAccepted(observations[1])
        })
      })

      it("shows only the steps that have been completed or attempted", (done) => {
        expectBrowserSpec("HtmlSpec", "targetUnknown", done, (observations) => {
          expect(observations[0].conditions).to.have.length(3)
          expect(observations[0].conditions[0]).to.equal("Describing: an html program")
          expect(observations[0].conditions[1]).to.equal("Scenario: targeting an unknown element")
          expect(observations[0].conditions[2]).to.equal("When the button is clicked three times")
        })
      })
    })
  })

  context("select elements", () => {
    it("selects all the elements to observe", (done) => {
      expectPassingBrowserSpec("HtmlSpec", "manyElements", done)
    })
  })

  context("observe presence", () => {
    it("observes presence and absence as expected", (done) => {
      expectBrowserSpec("HtmlSpec", "observePresence", done, (observations) => {
        expectAccepted(observations[0])

        expectRejected(observations[1], [
          reportLine("Claim rejected for selector", "#my-name"),
          reportLine("Expected", "nothing"),
          reportLine("but found", "something")
        ])

        expectAccepted(observations[2])

        expectRejected(observations[3], [
          reportLine("Claim rejected for selector", "#nothing"),
          reportLine("Expected", "something"),
          reportLine("but found", "nothing")
        ])
      })
    })
  })
})