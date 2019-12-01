const chai = require('chai')
const expect = chai.expect
const Reporter = require('../src/consoleReporter')

describe("reporter", () => {
  it("counts the number of accepted observations", () => {
    const reporter = new Reporter((character) => {}, (line) => {})
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())
    reporter.record(acceptedMessage())
    reporter.record(acceptedMessage())

    expect(reporter.accepted).to.equal(3)
  })

  it("counts the number of rejected observations", () => {
    const reporter = new Reporter((character) => {}, (line) => {})
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())
    reporter.record(acceptedMessage())
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())

    expect(reporter.rejected.length).to.equal(2)
  })

  describe("when there are no rejected observations", () => {
    let lines

    beforeEach(() => {
      lines = []
      const subject = new Reporter((character) => {}, (line) => lines.push(line))

      subject.record(acceptedMessage())
      subject.record(acceptedMessage())
      subject.finish()
    })

    it("writes the reason for rejection", () => {
      expectToContain(lines, [
        "Accepted: 2"
      ])
    })
  })

  describe("when there are rejected observations", () => {
    let lines

    beforeEach(() => {
      lines = []
      const subject = new Reporter((character) => {}, (line) => lines.push(line))

      subject.record(rejectedMessage({
        conditions: [ "Given a subject", "When something happens" ],
        description: "It does something else",
        report: [
          { statement: "Expected the following", detail: "something" },
          { statement: "to be", detail: "something else" },
          { statement: "and a final statement", detail: null }
        ]
      }))
      subject.finish()
    })

    it("writes the reason for rejection", () => {
      expectToContain(lines, [
        "Accepted: 0",
        "Rejected: 1",
        "Failed to satisfy spec:",
        "Given a subject",
        "When something happens",
        "It does something else",
        "Expected the following",
        "something",
        "to be",
        "something else",
        "and a final statement",
      ])
    })
  })

  describe("when there is an error", () => {
    let lines

    beforeEach(() => {
      lines = []
      const subject = new Reporter((character) => {}, (line) => lines.push(line))

      subject.error([
        { statement: "You received an error", detail: "something" },
        { statement: "and a final statement", detail: null }
      ])
      subject.finish()
    })

    it("writes the error", () => {
      expectToContain(lines, [
        "Error running spec suite!",
        "You received an error",
        "something",
        "and a final statement",
        "Accepted: 0",
      ])
    })
  })
})

const expectToContain = (actualLines, expectedLines) => {
  const output = actualLines.join("\n")
  for (let i = 0; i < expectedLines.length; i++) {
    expect(output).to.contain(expectedLines[i])
  }
}

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