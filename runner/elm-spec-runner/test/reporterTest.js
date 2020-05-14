const chai = require('chai')
const expect = chai.expect
const Reporter = require('../src/consoleReporter')

describe("reporter", () => {
  it("counts the number of accepted observations", () => {
    const reporter = new Reporter({ write: (character) => {}, writeLine: (line) => {} })
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())
    reporter.record(acceptedMessage())
    reporter.record(acceptedMessage())

    expect(reporter.accepted).to.equal(3)
  })

  it("counts the number of rejected observations", () => {
    const reporter = new Reporter({ write: (character) => {}, writeLine: (line) => {} })
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())
    reporter.record(acceptedMessage())
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())

    expect(reporter.rejected.length).to.equal(2)
  })

  it("counts the number of skipped observations", () => {
    const reporter = new Reporter({ write: (character) => {}, writeLine: (line) => {} })
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())
    reporter.record(acceptedMessage())
    reporter.record(skippedMessage())
    reporter.record(acceptedMessage())
    reporter.record(skippedMessage())
    reporter.record(skippedMessage())
    reporter.record(rejectedMessage())

    expect(reporter.skipped).to.equal(3)
  })

  describe("when there are no rejected or skipped observations", () => {
    let lines

    beforeEach(() => {
      lines = []
      const subject = new Reporter({ write: (character) => {}, writeLine: (line) => lines.push(line) })

      subject.record(acceptedMessage())
      subject.record(acceptedMessage())
      subject.finish()
    })

    it("writes just the number accepted", () => {
      expectToContain(lines, [
        "Accepted: 2"
      ])
    })
  })

  describe("when there are skipped observations", () => {
    let lines

    beforeEach(() => {
      lines = []
      const subject = new Reporter({ write: (character) => {}, writeLine: (line) => lines.push(line) })

      subject.record(acceptedMessage())
      subject.record(skippedMessage())
      subject.record(acceptedMessage())
      subject.record(skippedMessage())
      subject.record(skippedMessage())
      subject.finish()
    })

    it("writes the number skipped", () => {
      expectToContain(lines, [
        "Accepted: 2",
        "Skipped: 3"
      ])
    })
  })

  describe("when there are rejected observations but none skipped", () => {
    let lines
    let subject

    beforeEach(() => {
      lines = []
      subject = new Reporter({
        write: (character) => {},
        writeLine: (line) => lines.push(line)
      })

      subject.record(rejectedMessage({
        conditions: [ "Given a subject", "When something happens" ],
        description: "It does something else",
        report: [
          { statement: "Expected the following", detail: "something" },
          { statement: "to be", detail: "something else\nwith\nmultiple lines" },
          { statement: "and a final statement\nthat has multiple\nlines", detail: null }
        ],
        modulePath: "/base/path/elm/specs/Some/Funny/RejectedSpec.elm"
      }))
      subject.finish()
    })

    it("writes the reason for rejection", () => {
      expectToContain(lines, [
        "Accepted: 0",
        "Rejected: 1",
        "Failed to satisfy spec:",
        "/base/path/elm/specs/Some/Funny/RejectedSpec.elm",
        "Given a subject",
        "When something happens",
        "It does something else",
        "Expected the following",
        "something",
        "to be",
        "something else",
        "with",
        "multiple lines",
        "and a final statement",
        "that has multiple",
        "lines"
      ])
    })

    it("shows there was no error", () => {
      expect(subject.hasError).to.be.false
    })
  })

  describe("when there is an error", () => {
    let lines
    let subject

    beforeEach(() => {
      lines = []
      subject = new Reporter({ write: (character) => {}, writeLine: (line) => lines.push(line), specFiles: [] })

      subject.error([
        { statement: "You received an error", detail: "something" },
        { statement: "and a final statement\nwith multiple lines", detail: null }
      ])
      subject.finish()
    })

    it("writes the error", () => {
      expectToContain(lines, [
        "Error running spec suite!",
        "You received an error",
        "something",
        "and a final statement",
        "with multiple lines"
      ])
    })

    it("records that an error occurred", () => {
      expect(subject.hasError).to.be.true
    })
  })

  context("when there is a log message", () => {
    let lines
    let subject

    beforeEach(() => {
      lines = []
      subject = new Reporter({ write: (character) => {}, writeLine: (line) => lines.push(line), specFiles: [] })

      subject.log([
        { statement: "Log message one", detail: "with some detail" },
      ])

      subject.log([
        { statement: "Log message two!", detail: null }
      ])

      subject.finish()
    })

    it("writes the log message", () => {
      expectToContain(lines, [
        "Log message one",
        "with some detail",
        "Log message two!",
        "Accepted: 0"
      ])
    })
  })

  context("when the reporter is reset, like when in watch mode", () => {
    let lines

    beforeEach(() => {
      lines = []
      const subject = new Reporter({ write: (character) => {}, writeLine: (line) => lines.push(line) })

      subject.record(acceptedMessage())
      subject.record(skippedMessage())
      subject.record(acceptedMessage())
      subject.record(rejectedMessage({
        conditions: [ "Given a subject", "When something happens" ],
        description: "It does something else",
        report: [
          { statement: "Expected the following", detail: "something" },
          { statement: "to be", detail: "something else\nwith\nmultiple lines" },
          { statement: "and a final statement\nthat has multiple\nlines", detail: null }
        ],
        modulePath: "/base/path/elm/specs/Some/Funny/RejectedSpec.elm"
      }))
      subject.finish()
      subject.reset()
      subject.record(acceptedMessage())
      subject.record(acceptedMessage())
      subject.record(acceptedMessage())
      subject.record(acceptedMessage())
      subject.finish()
    })

    it("clears the number of accepted, skipped, rejected", () => {
      expectToContain(lines, [
        "Accepted: 2",
        "Skipped: 1",
        "Rejected: 1",
        "Failed to satisfy spec:",
        "/base/path/elm/specs/Some/Funny/RejectedSpec.elm",
        "Given a subject",
        "When something happens",
        "It does something else",
        "Expected the following",
        "something",
        "to be",
        "something else",
        "with",
        "multiple lines",
        "and a final statement",
        "that has multiple",
        "lines",
        "Accepted: 4"
      ])
    })
  })
})

const expectToContain = (actualLines, expectedLines) => {
  const actualWithoutBlanks = actualLines.filter(line => line !== "\n" && line !== undefined)
  expectedLines.forEach((expectedLine, index) => {
    expect(index, `Expected at least ${index + 1} actual lines, but there are only ${actualWithoutBlanks.length}`).to.be.lessThan(actualWithoutBlanks.length)
    expect(actualWithoutBlanks[index]).to.contain(expectedLine)
  })
  expect(expectedLines.length, "Number of actual lines does not equal number of expected lines").to.equal(actualWithoutBlanks.length)
}

const acceptedMessage = (data = { conditions: [], description: '' }) => {
  return {
    summary: 'ACCEPT',
    conditions: data.conditions,
    description: data.description,
    modulePath: [ "Some", "Behavior", "PassingSpec" ]
  }
}

const rejectedMessage = (data = { conditions: [], description: '', message: '', report: [], modulePath: [ "Some", "FailingSpec" ] }) => {
  return {
    summary: 'REJECT',
    conditions: data.conditions,
    description: data.description,
    report: data.report,
    modulePath: data.modulePath
  }
}

const skippedMessage = () => {
  return {
    summary: 'SKIPPED',
    conditions: [],
    description: "",
    modulePath: [ "Some", "Behavior", "SkippedSpec" ]
  }
}
