const chai = require('chai')
const expect = chai.expect
const Reporter = require('../src/reporter')

describe("reporter", () => {
  it("counts the number of accepted observations", () => {
    const reporter = new Reporter()
    reporter.record({ summary: 'ACCEPT' })
    reporter.record({ summary: 'REJECT' })
    reporter.record({ summary: 'ACCEPT' })
    reporter.record({ summary: 'ACCEPT' })

    expect(reporter.accepted).to.equal(3)
  })

  it("counts the number of rejected observations", () => {
    const reporter = new Reporter()
    reporter.record({ summary: 'ACCEPT' })
    reporter.record({ summary: 'REJECT' })
    reporter.record({ summary: 'ACCEPT' })
    reporter.record({ summary: 'ACCEPT' })
    reporter.record({ summary: 'REJECT' })

    expect(reporter.rejected).to.equal(2)
  })
})