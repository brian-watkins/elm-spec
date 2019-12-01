const chalk = require('chalk')

const ok = chalk.green
const error = chalk.red

module.exports = class ConsoleReporter {
  constructor(write, writeLine) {
    this.accepted = 0
    this.rejected = []
    this.write = write
    this.writeLine = writeLine
  }

  startSuite() {
    this.write("\nRunning specs: ")
  }

  record(observation) {
    if (observation.summary === "ACCEPT") {
      this.accepted += 1
      this.write(ok('.'))
    }
    else if (observation.summary === "REJECT") {
      this.rejected.push(observation)
      this.write(error('x'))
    }
  }

  error(err) {
    this.writeLine("Error running spec suite!")
    this.writeLine()
    err.forEach(r => this.printReport(r))
  }

  finish() {
    this.writeLine("\n")
    this.writeLine(ok(`Accepted: ${this.accepted}`))
    if (this.rejected.length > 0) {
      this.writeLine(error(`Rejected: ${this.rejected.length}`))
      this.rejected.forEach(o => this.printRejection(o))
    } else {
      this.writeLine()
    }
  }

  printConditions(conditions) {
    this.writeLine(`  ${conditions[0]}`)
    this.writeLine()
    this.writeLine(`  ${conditions[1]}`)
    conditions.slice(2).forEach((condition) => {
      this.writeLine(`    ${condition}`)
    })
  }

  printRejection(observation) {
    this.writeLine(error("\nFailed to satisfy spec:"))
    this.writeLine()
    this.printConditions(observation.conditions)
    this.writeLine(`    ${observation.description}`)
    this.writeLine()
    observation.report.forEach(r => this.printReport(r))
  }

  printReport(report) {
    this.writeLine(error(`    ${report.statement}`))
    if (report.detail) {
      this.writeLine(error(`      ${report.detail}`))
    }
    this.writeLine()
  }
}

