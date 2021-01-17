module.exports = class TestReporter {
  constructor() {
    this.observations = []
    this.specError = null
  }

  startSuite() {
    // Nothing
  }

  record(observation) {
    this.observations.push(observation)
  }

  finish() {}

  error(err) {
    this.specError = err
  }
}