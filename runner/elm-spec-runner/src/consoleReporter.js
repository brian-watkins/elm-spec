const chalk = require('chalk')
const path = require('path')

const ok = chalk.green
const error = chalk.red

module.exports = class ConsoleReporter {
  constructor({ write, writeLine, specFiles }) {
    this.accepted = 0
    this.rejected = []
    this.write = write
    this.writeLine = writeLine
    this.hasError = false
    this.specFiles = specFiles
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
    this.hasError = true
  }

  finish() {
    if (this.hasError) return

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
    this.printModulePath(observation.modulePath)
    this.printConditions(observation.conditions)
    this.writeLine(`    ${observation.description}`)
    this.writeLine()
    observation.report.forEach(r => this.printReport(r))
  }

  printReport(report) {
    const statementLines = report.statement.split("\n")
    statementLines.forEach(line => {
      this.writeLine(error(`    ${line}`))
    })
    if (report.detail) {
      const detailLines = report.detail.split("\n")
      detailLines.forEach(line => {
        this.writeLine(error(`      ${line}`))
      })
    }
    this.writeLine()
  }

  printModulePath(modulePath) {
    const modulePathString = path.join(...modulePath) + ".elm"
    const fullPath = this.specFiles.find(filePath => filePath.endsWith(modulePathString))
    this.writeLine(`  ${fullPath}`)
    this.writeLine()
  }
}

