const chai = require('chai')
const expect = chai.expect
const Reporter = require('../src/consoleReporter')

describe("reporter", () => {
  let testHarness
  let reporter

  beforeEach(() => {
    testHarness = new TestHarness()
    reporter = testHarness.reporter
  })

  it("counts the number of accepted observations", () => {
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())
    reporter.record(acceptedMessage())
    reporter.record(acceptedMessage())

    expect(reporter.accepted).to.equal(3)
  })

  it("counts the number of rejected observations", () => {
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())
    reporter.record(acceptedMessage())
    reporter.record(acceptedMessage())
    reporter.record(rejectedMessage())

    expect(reporter.rejected.length).to.equal(2)
  })

  it("counts the number of skipped observations", () => {
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

  it("prints the duration", () => {
    reporter.startSuite()
    reporter.record(acceptedMessage())
    reporter.record(acceptedMessage())
    reporter.record(acceptedMessage())
    testHarness.testTimer.time = 76222
    reporter.finish()
    
    expect(testHarness.header).to.contain("76.2s")
  })

  describe("when there are no rejected or skipped observations", () => {
    beforeEach(() => {
      reporter.startSuite()
      testHarness.testTimer.time = 29987  
      reporter.record(acceptedMessage())
      reporter.record(acceptedMessage())
      reporter.finish()
    })

    it("writes just the number accepted", () => {
      expectToContain(testHarness.lines, [
        "Accepted: 2",
      ])
    })
  })

  describe("when there are skipped observations", () => {
    beforeEach(() => {
      reporter.record(acceptedMessage())
      reporter.record(skippedMessage())
      reporter.record(acceptedMessage())
      reporter.record(skippedMessage())
      reporter.record(skippedMessage())
      reporter.finish()
    })

    it("writes the number skipped", () => {
      expectToContain(testHarness.lines, [
        "Accepted: 2",
        "Skipped: 3"
      ])
    })
  })

  describe("when there are rejected observations but none skipped", () => {
    beforeEach(() => {
      reporter.record(rejectedMessage({
        conditions: [ "Given a subject", "When something happens" ],
        description: "It does something else",
        report: [
          { statement: "Expected the following", detail: "something" },
          { statement: "to be", detail: "something else\nwith\nmultiple lines" },
          { statement: "and a final statement\nthat has multiple\nlines", detail: null }
        ],
        modulePath: "/base/path/elm/specs/Some/Funny/RejectedSpec.elm"
      }))
      reporter.finish()
    })

    it("writes the reason for rejection", () => {
      expectToContain(testHarness.lines, [
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
      expect(reporter.hasError).to.be.false
    })
  })

  describe("when there are multiple parallel segments", () => {
    beforeEach(() => {
      reporter.startSuite()
      reporter.startSuite()
      reporter.startSuite()

      reporter.record(acceptedMessage())
      reporter.record(rejectedMessage({
        conditions: [ "Given a subject", "When something happens" ],
        description: "It does something else",
        report: [
          { statement: "Expected something", detail: "cool" }
        ],
        modulePath: "/base/path/elm/specs/Some/Funny/RejectedSpec.elm"
      }))
      reporter.record(acceptedMessage())
      reporter.record(acceptedMessage())
      reporter.record(acceptedMessage())

      reporter.finish()
      reporter.finish()
      reporter.finish()
    })

    it("writes the expected test output once", () => {
      expect(testHarness.header).to.have.entriesCount("Running specs:", 1)
      expectToContain(testHarness.lines, [
        "Accepted: 4",
        "Rejected: 1",
        "Failed to satisfy spec:",
        "/base/path/elm/specs/Some/Funny/RejectedSpec.elm",
        "Given a subject",
        "When something happens",
        "It does something else",
        "Expected something",
        "cool"
      ])
    })
  })

  describe("when there is an error", () => {
    beforeEach(() => {
      reporter.error([
        { statement: "You received an error", detail: "something" },
        { statement: "and a final statement\nwith multiple lines", detail: null }
      ])
      reporter.finish()
    })

    it("writes the error", () => {
      expectToContain(testHarness.lines, [
        "Error running spec suite!",
        "You received an error",
        "something",
        "and a final statement",
        "with multiple lines"
      ])
    })

    it("records that an error occurred", () => {
      expect(reporter.hasError).to.be.true
    })
  })

  context("when there is an error and multiple parallel segments", () => {
    beforeEach(() => {
      reporter.error([
        { statement: "You received one error", detail: "something" },
        { statement: "and a final statement\nwith multiple lines", detail: null }
      ])
      reporter.finish()
      reporter.error([
        { statement: "You received a second error", detail: "something" },
        { statement: "and a final statement\nwith multiple lines", detail: null }
      ])
      reporter.finish()
      reporter.error([
        { statement: "You received a third error", detail: "something" },
        { statement: "and a final statement\nwith multiple lines", detail: null }
      ])
      reporter.finish()
    })

    it("writes only the first error", () => {
      expectToContain(testHarness.lines, [
        "Error running spec suite!",
        "You received one error",
        "something",
        "and a final statement",
        "with multiple lines"
      ])
    })
  })

  context("when there is a log message", () => {
    beforeEach(() => {
      reporter.log([
        { statement: "Log message one", detail: "with some detail" },
      ])

      reporter.log([
        { statement: "Log message two!", detail: null }
      ])

      reporter.finish()
    })

    it("writes the log message", () => {
      expectToContain(testHarness.lines, [
        "Log message one",
        "with some detail",
        "Log message two!",
        "Accepted: 0"
      ])
    })
  })

  context("when the reporter is reset, like when in watch mode", () => {
    beforeEach(() => {
      reporter.record(acceptedMessage())
      reporter.record(skippedMessage())
      reporter.record(acceptedMessage())
      reporter.record(rejectedMessage({
        conditions: [ "Given a subject", "When something happens" ],
        description: "It does something else",
        report: [
          { statement: "Expected the following", detail: "something" },
          { statement: "to be", detail: "something else\nwith\nmultiple lines" },
          { statement: "and a final statement\nthat has multiple\nlines", detail: null }
        ],
        modulePath: "/base/path/elm/specs/Some/Funny/RejectedSpec.elm"
      }))
      reporter.finish()
      reporter.reset()
      reporter.record(acceptedMessage())
      reporter.record(acceptedMessage())
      reporter.record(acceptedMessage())
      reporter.record(acceptedMessage())
      reporter.finish()
    })

    it("clears the number of accepted, skipped, rejected", () => {
      expectToContain(testHarness.lines, [
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

class TestHarness {
  constructor() {
    this.testTimer = new TestTimer()
    this.lines = []
    this.header = ""
    this.reporter = new Reporter(this.testTimer, {
      write: (character) => { this.header += character },
      writeLine: (line) => this.lines.push(line)
    })
  }
}

class TestTimer {
  constructor() {
    this.time = 1276
  }

  start() {}

  stop() {}

  getTime() {
    return this.time
  }
}


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
    summary: 'ACCEPTED',
    conditions: data.conditions,
    description: data.description,
    modulePath: [ "Some", "Behavior", "PassingSpec" ]
  }
}

const rejectedMessage = (data = { conditions: [], description: '', message: '', report: [], modulePath: [ "Some", "FailingSpec" ] }) => {
  return {
    summary: 'REJECTED',
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
