const chai = require('chai')
const expect = chai.expect
const Reporter = require('../elm-spec-runner/src/spec/consoleReporter')

describe("reporter", () => {
  it("counts the number of accepted observations", () => {
    const reporter = new Reporter((line) => {})
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())
    reporter.record(acceptedMessage())
    reporter.record(acceptedMessage())

    expect(reporter.accepted).to.equal(3)
  })

  it("counts the number of rejected observations", () => {
    const reporter = new Reporter((line) => {})
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())
    reporter.record(acceptedMessage())
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())

    expect(reporter.rejected).to.equal(2)
  })

  describe("when there are rejected observations", () => {
    let lines

    beforeEach(() => {
      lines = []
      const subject = new Reporter((line) => lines.push(line))

      subject.record(rejectedMessage({
        conditions: [ "Given a subject", "When something happens" ],
        description: "It does something else",
        report: [
          { statement: "Expected the following", detail: "something" },
          { statement: "to be", detail: "something else" },
          { statement: "and a final statement", detail: null }
        ]
      }))
    })

    it("writes the reason for rejection", () => {
      expect(lines).to.deep.equal([
        "\nFailed to satisfy spec!\n",
        "\tGiven a subject",
        "\tWhen something happens",
        "\tIt does something else",
        "Expected the following",
        "\tsomething",
        "to be",
        "\tsomething else",
        "and a final statement"
      ])
    })
  })
})

const acceptedMessage = (data = { conditions: [], description: '' }) => {
  return {
    summary: 'ACCEPT',
    conditions: data.conditions,
    description: data.description
  }
}

const rejectedMessage = (data = { conditions: [], description: '', message: '', report: [] }) => {
  return {
    summary: 'REJECT',
    conditions: data.conditions,
    description: data.description,
    report: data.report
  }
}