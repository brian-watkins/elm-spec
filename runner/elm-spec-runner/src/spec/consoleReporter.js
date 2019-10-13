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
    this.writeLine("Error running Spec!")
    this.writeLine(err)
  }

  finish() {
    this.writeLine("\n")
    this.writeLine(ok(`Accepted: ${this.accepted}`))
    if (this.rejected.length > 0) {
      this.writeLine(error(`Rejected: ${this.rejected.length}`))
      this.rejected.forEach(o => this.printRejection(o))
    }
  }

  printRejection(observation) {
    this.writeLine(error("\nFailed to satisfy spec:"))
    observation.conditions.forEach(c => this.writeLine(error(`  ${c}`)))
    this.writeLine(error(`  ${observation.description}\n`))
    observation.report.forEach(report => {
      this.writeLine(error(`  ${report.statement}`))
      if (report.detail) {
        this.writeLine(error(`    ${report.detail}`))
      }
    })
    console.log()
  }
}

