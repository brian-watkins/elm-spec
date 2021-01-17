const chai = require('chai')
const expect = chai.expect
const {
  expectSpec,
  expectAccepted,
  reportLine
} = require("./helpers/SpecHelpers")

describe("log report command", () => {
  it("logs a report", (done) => {
    expectSpec("LogSpec", "logReport", done, (observations, error, logs) => {
      expectAccepted(observations[0])
      expect(logs).to.deep.equal([
        [ reportLine("This is a log message!"), reportLine("And this is another message!") ],
        [ reportLine("This is the count in the model!", "7") ]
      ])
    })
  })
})