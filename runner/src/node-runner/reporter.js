
module.exports = class Reporter {
  constructor(write) {
    this.accepted = 0
    this.rejected = 0
    this.write = write
  }

  record(observation) {
    if (observation.summary === "ACCEPT") {
      this.accepted += 1
    }
    else if (observation.summary === "REJECT") {
      this.rejected += 1
      this.write("\nSubject does not satisfy the specification:\n")
      observation.conditions.forEach(c => this.write(`\t${c}`))
      this.write(`\t${observation.description}`)
      this.write(`\n\t${observation.message}\n`)
    }
  }
}
