const { expectSpec, expectAccepted, expectRejected, reportLine } = require("./helpers/SpecHelpers")

describe("form inputs", () => {
  describe("checking a box", () => {
    it("respnds as expected to onCheck events", (done) => {
      expectSpec("FormSpec", "check", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("No element targeted for event", "toggle")
        ])
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

  describe("Submit", () => {
    it("handles the onSubmit event as expected", (done) => {
      expectSpec("FormSpec", "submit", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
      })
    })
  })
})