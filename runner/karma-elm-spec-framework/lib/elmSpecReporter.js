const chalk = require('chalk')

const ok = chalk.green
const error = chalk.red

var ElmSpecReporter = function (baseReporterDecorator) {
  baseReporterDecorator(this);

  var self = this;

  self.specSuccess = function() {
    self.write(ok("."))
  }

  self.onRunStart = function() {
    self.failures = []
    self._browsers = []
    self.hasError = false
  }

  self.onBrowserStart = function(browser) {
    self._browsers.push(browser)
    self.write("\nRunning specs: ")
  }

  self.onBrowserError = function(browser, error) {
    self.write("\n\n")
    if (typeof(error) === "string") {
      self.write(error)
    } else {
      self.write("Error running spec suite!\n\n")
      error.message.forEach((report) => self.printReport(report))  
    }

    self.hasError = true
  }

  self.specFailure = function(browser, result) {
    self.failures.push(result)
    self.write(error("x"))
  }

  self.printSuite = function(suite) {
    self.write(`  ${suite[0]}\n\n`)
    self.write(`  ${suite[1]}\n`)
    const conditions = suite.slice(2)
    conditions.forEach((condition) => {
      self.write(`    ${condition}\n`)
    })
  }

  self.printRejection = function(result) {
    self.write(error("\nFailed to satisfy spec:\n\n"))
    self.write(`  ${result.elmSpec.modulePath}\n\n`)
    self.printSuite(result.suite)
    self.write(`    ${result.description}\n\n`)
    result.log.forEach(report => self.printReport(report))
  }  

  self.printReport = function(report) {
    const statementLines = report.statement.split("\n")
    statementLines.forEach(line => {
      self.write(error(`    ${line}\n`))
    })
    if (report.detail) {
      const detailLines = report.detail.split("\n")
      detailLines.forEach(line => {
        self.write(error(`      ${line}\n`))
      })
    }
    self.write('\n')
  }

  self.onRunComplete = function(browsers, results) {
    if (self.hasError) return

    self.write("\n\n")
    self.write(ok(`Accepted: ${results.success}\n`))
    if (results.failed > 0) {
      self.write(error(`Rejected: ${results.failed}\n`))
      self.failures.forEach(r => self.printRejection(r))
    } else {
      self.write("\n")
    }
  }
}

ElmSpecReporter.$inject = ['baseReporterDecorator'];

module.exports = {
  ElmSpecReporter
}