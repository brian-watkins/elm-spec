const chai = require('chai')
const expect = chai.expect
const { ElmSpecReporter } = require('../lib/elmSpecReporter')

describe("elm-spec reporter", () => {
  let subject
  let words

  beforeEach(() => {
    words = []

    subject = new ElmSpecReporter((self) => {
      self.write = (line) => words.push(line)
    })
  })

  describe("when there are no rejected specs", () => {
    beforeEach(() => {
      subject.onRunStart()
      subject.onRunComplete(null, {
        success: 3,
        failed: 0
      })
    })

    it("prints only the accepted count", () => {
      const output = words.join("")
      expect(output).to.contain("Accepted: 3")
      expect(output).to.not.contain("Rejected")
    })
  })

  describe("when there are rejected specs", () => {
    beforeEach(() => {
      subject.onRunStart()
      subject.specFailure(null, failureResult())
      subject.specFailure(null, failureResultTwo())
      subject.onRunComplete(null, {
        success: 3,
        failed: 2
      })
    })

    it("prints the accepted and rejected count", () => {
      const output = words.join("")
      expect(output).to.contain("Accepted: 3")
      expect(output).to.contain("Rejected: 2")
    })

    it("prints rejections", () => {
      const output = words.join("")

      expect(output).to.contain("Describing: Something")
      expect(output).to.contain("Scenario: Something happens")
      expect(output).to.contain("When some event occurs")
      expect(output).to.contain("it failed to do something")

      expect(output).to.contain("Expected")
      expect(output).to.contain("7")
      expect(output).to.contain("to equal")
      expect(output).to.contain("5")

      expect(output).to.contain("Describing: Another Thing")
      expect(output).to.contain("Scenario: Something else happens")
      expect(output).to.contain("When some other event occurs")
      expect(output).to.contain("it failed to do another thing")

      expect(output).to.contain("Require")
      expect(output).to.contain("19")
      expect(output).to.contain("to be")
      expect(output).to.contain("2")
    })
  })
})

const failureResult = () => {
  return {
    id: "obs-1",
    description: "it failed to do something",
    suite: [
      "Describing: Something",
      "Scenario: Something happens",
      "When some event occurs"
    ],
    log: [
      { statement: "Expected",
        detail: "7"
      },
      { statement: "to equal",
        detail: "5"
      }
    ],
    success: false,
    skipped: false
  }
}

const failureResultTwo = () => {
  return {
    id: "obs-1",
    description: "it failed to do another thing",
    suite: [
      "Describing: Another Thing",
      "Scenario: Something else happens",
      "When some other event occurs"
    ],
    log: [
      { statement: "Required",
        detail: "19"
      },
      { statement: "to be",
        detail: "2"
      }
    ],
    success: false,
    skipped: false
  }
}