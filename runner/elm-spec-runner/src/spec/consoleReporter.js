
module.exports = class ConsoleReporter {
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
      this.write("\nFailed to satisfy spec!\n")
      observation.conditions.forEach(c => this.write(`\t${c}`))
      this.write(`\t${observation.description}`)
      observation.report.forEach(report => {
        this.write(report.statement)
        if (report.detail) {
          this.write(`\t${report.detail}`)
        }
      })
    }
  }

  error(err) {
    this.write("Error running Spec!")
    this.write(err)
  }

  finish() {
    this.write("Finished!!!")
    this.write(`Accepted: ${this.accepted}`)
    this.write(`Rejected: ${this.rejected}`)
  }
}
