module.exports = class TestReporter {
  constructor() {
    this.observations = []
  }

  startSuite() {
    // Nothing
  }

  record(observation) {
    this.observations.push(observation)
  }

  finish() {}

  error(err) {
    throw err
  }
}