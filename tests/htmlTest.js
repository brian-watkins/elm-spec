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

  context("click event", () => {
    it("handles the click event as expected", (done) => {
      expectPassingBrowserSpec("HtmlSpec", "click", done)
    })
  })

  context("target element", () => {
    context("when the target fails to select an element", () => {
      it("fails before any observations or other scenarios and reports the reason", (done) => {
        expectFailingBrowserSpec("HtmlSpec", "targetUnknown", done, (observations) => {
          expect(observations).to.have.length(1)
          expectRejected(observations[0], [
            reportLine("No match for selector", "#some-element-that-does-not-exist")
          ])
        })
      })

      it("shows only the steps that have been completed or attempted", (done) => {
        expectFailingBrowserSpec("HtmlSpec", "targetUnknown", done, (observations) => {
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

  context("expect nothing selected", () => {
    it("uses the expectAbsent observer as expected", (done) => {
      expectBrowserSpec("HtmlSpec", "expectAbsent", done, (observations) => {
        expectAccepted(observations[0])

        expectRejected(observations[1], [
          reportLine("Expected no elements to be selected with", "#my-name"),
          reportLine("but one or more elements were selected")
        ])
      })
    })
  })
})