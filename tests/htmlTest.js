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
        expect(observations[1].summary).to.equal("REJECT")
        expect(observations[1].message).to.equal("No element matches selector:\n\t#something-not-present")
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
        expect(observations[0].message).to.equal("Expected text\n\tSomething not present\nbut the actual text was\n\tHello, Cool Dude!")
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
          expect(observations[0].message).to.equal("No match for selector: #some-element-that-does-not-exist")
        })
      })

      it("shows only the steps that have been completed or attempted", (done) => {
        expectFailingBrowserSpec("HtmlSpec", "targetUnknown", done, (observations) => {
          expect(observations[0].conditions).to.have.length(2)
          expect(observations[0].conditions[0]).to.equal("Given an html program that targets an unknown element")
          expect(observations[0].conditions[1]).to.equal("When the button is clicked three times")
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