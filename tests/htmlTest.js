const chai = require('chai')
const expect = chai.expect
const { 
  expectFailingBrowserSpec,
  expectPassingBrowserSpec,
  expectBrowserSpec
} = require("./helpers/SpecHelpers")

describe("html plugin", () => {
  context("when a single element is selected", () => {
    it("selects an existing element", (done) => {
      expectBrowserSpec("HtmlSpec", "single", done, (observations) => {
        expect(observations[0].summary).to.equal("ACCEPT")
      })
    })
    it("fails when selecting an element that does not exist", (done) => {
      expectBrowserSpec("HtmlSpec", "single", done, (observations) => {
        expect(observations[1].description).to.equal("It does not find an element that is not there")
        expect(observations[1].summary).to.equal("REJECT")
        expect(observations[1].report).to.deep.equal([{
          statement: "No element matches selector",
          detail: "#something-not-present"
        }])
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

  context("hasText", () => {
    it("prints the proper error message", (done) => {
      expectFailingBrowserSpec("HtmlSpec", "hasTextFails", done, (observations) => {
        expect(observations[0].report).to.deep.equal([
          { statement: "Expected text", detail: "Something not present" }, 
          { statement: "but the actual text was", detail: "Hello, Cool Dude!" }
        ])
      })
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
          expect(observations[0].report).to.deep.equal([{
            statement: "No match for selector",
            detail: "#some-element-that-does-not-exist"
          }])
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
})