const chai = require('chai')
const expect = chai.expect
const Reporter = require('../src/node-runner/reporter')

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
        message: "Expected something else to happen but it did not"
      }))
    })

    it("writes the reason for rejection", () => {
      expect(lines).to.deep.equal([
        "\nSubject does not satisfy the specification:\n",
        "\tGiven a subject",
        "\tWhen something happens",
        "\tIt does something else",
        "\n\tExpected something else to happen but it did not\n"
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

const rejectedMessage = (data = { conditions: [], description: '', message: '' }) => {
  return {
    summary: 'REJECT',
    conditions: data.conditions,
    description: data.description,
    message: data.message
  }
}