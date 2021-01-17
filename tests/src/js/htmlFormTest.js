const {
  expectSpec,
  expectAccepted
} = require("./helpers/SpecHelpers")
const {
  expectRejectedWhenDocumentTargeted,
  expectRejectedWhenNoElementTargeted
} = require("./helpers/eventTestHelpers")

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
          expectRejectedWhenNoElementTargeted("input", observations[1])
          expectRejectedWhenDocumentTargeted("input", observations[2])
        })
      })
    })
  })

  describe("focus and blur", () => {
    context("input field", () => {
      it("handles focus and blur events as expected", (done) => {
        expectSpec("FormSpec", "focusBlur", done, (observations) => {
          expectAccepted(observations[0])
          expectAccepted(observations[1])
          expectRejectedWhenNoElementTargeted("focus", observations[2])
          expectRejectedWhenDocumentTargeted("focus", observations[3])
          expectRejectedWhenNoElementTargeted("blur", observations[4])
          expectRejectedWhenDocumentTargeted("blur", observations[5])
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
          expectRejectedWhenNoElementTargeted("select", observations[3])
          expectRejectedWhenDocumentTargeted("select", observations[4])
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