const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("form inputs", () => {
  describe("checking a box", () => {
    it("respnds as expected to onCheck events", (done) => {
      expectSpec("FormSpec", "check", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  describe("Input", () => {
    context("when text is input to a targeted field", () => {
      it("updates the model and renders the view as expected", (done) => {
        expectSpec("FormSpec", "input", done, (observations) => {
          expectAccepted(observations[0])
          expectRejected(observations[1], [
            reportLine("No element targeted for event", "input")
          ])
        })
      })
    })
  })

  describe("radio buttons", () => {
    it("handles input events on radio buttons as expected", (done) => {
      expectSpec("FormSpec", "radio", done, (observations) => {
        expectAccepted(observations[0])
      })
    })
  })

  describe("select", () => {
    context("by text", () => {
      it("triggers an event when an option is selected", (done) => {
        expectSpec("FormSpec", "selectByText", done, (observations) => {
          expectAccepted(observations[0])
          expectAccepted(observations[1])
          expectAccepted(observations[2])
        })
      })
    })
  })

  describe("Submit", () => {
    it("handles the onSubmit event as expected", (done) => {
      expectSpec("FormSpec", "submit", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })
})