const chai = require('chai')
const expect = chai.expect
const { 
  expectPassingSpec,
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("html plugin", () => {
  context("when a single element is selected", () => {
    it("selects an existing element", (done) => {
      expectSpec("HtmlSpec", "single", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
    it("fails when selecting an element that does not exist", (done) => {
      expectSpec("HtmlSpec", "single", done, (observations) => {
        expect(observations[1].description).to.equal("It does not find an element that is not there")
        expectRejected(observations[1], [
          reportLine("Claim rejected for selector", "#something-not-present"),
          reportLine("Expected", "something"),
          reportLine("but found", "nothing")
        ])
      })
    })
  })

  context("when there are multiple distinct (deferred) observations about the html", () => {
    it("handles selecting the appropriate element for each observation", (done) => {
      expectPassingSpec("HtmlSpec", "multiple", done, (observations) => {
        expect(observations).to.have.length(4)
      })
    })  
  })

  context("when the model is updated", () => {
    it("updates the view as expected", (done) => {
      expectPassingSpec("HtmlSpec", "sub", done)
    })
  })

  context("target element", () => {
    context("when the target fails to select an element", () => {
      it("fails and reports the reason and runs the next scenario", (done) => {
        expectSpec("HtmlSpec", "targetUnknown", done, (observations) => {
          expectRejected(observations[0], [
            reportLine("No match for selector", "#some-element-that-does-not-exist")
          ])
          expectAccepted(observations[1])
        })
      })

      it("shows only the steps that have been completed or attempted", (done) => {
        expectSpec("HtmlSpec", "targetUnknown", done, (observations) => {
          expect(observations[0].conditions).to.have.length(3)
          expect(observations[0].conditions[0]).to.equal("an html program")
          expect(observations[0].conditions[1]).to.equal("Scenario: targeting an unknown element")
          expect(observations[0].conditions[2]).to.equal("When the button is clicked three times")
        })
      })
    })
  })

  context("select elements", () => {
    it("selects all the elements to observe", (done) => {
      expectPassingSpec("HtmlSpec", "manyElements", done)
    })
  })

  context("observe presence", () => {
    it("observes presence and absence as expected", (done) => {
      expectSpec("HtmlSpec", "observePresence", done, (observations) => {
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

  context("element applications with a link", () => {
    it("handles clicks on a link as expected", (done) => {
      expectSpec("HtmlSpec", "elementLink", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  context("log element", () => {
    it("logs the element", (done) => {
      expectSpec("HtmlSpec", "logElement", done, (observations, error, logs) => {
        expectAccepted(observations[0])
        expect(logs[0]).to.deep.equal([
          reportLine("HTML for element: #my-name", "<div id=\"my-name\" class=\"pretty\">Hello, Fun Person!</div>")
        ])

        expectAccepted(observations[1])
        expect(logs[1]).to.deep.equal([
          reportLine("No element found for selector", "#unknown-element")
        ])
      })
    })
  })
})