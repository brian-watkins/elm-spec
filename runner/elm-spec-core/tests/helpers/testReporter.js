module.exports = class TestReporter {
  constructor() {
    this.observations = []
    this.specError = null
    this.logs = []
    this.errorCount = 0
  }

  startSuite() {
    // Nothing
  }

  record(observation) {
    this.observations.push(observation)
  }

  finish() {}

  error(err) {
    this.errorCount += 1
    this.specError = err
  }

  log(report) {
    this.logs.push(report)
  }
}