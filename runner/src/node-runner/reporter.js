
module.exports = class Reporter {
  constructor() {
    this.accepted = 0
    this.rejected = 0
  }

  record(observation) {
    if (observation.summary === "ACCEPT") {
      this.accepted += 1
    }
    else if (observation.summary === "REJECT") {
      this.rejected += 1
    }
  }
}
