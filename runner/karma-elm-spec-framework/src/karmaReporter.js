
module.exports = class KarmaReporter {

  constructor(karma) {
    this.karma = karma
    this.karma.info({total: 1})
  }

  startSuite() {
    // Nothing
  }

  record(observation) {
    this.karma.result({
      id: "obs-1",
      description: observation.description,
      suite: observation.conditions,
      log: observation.report,
      success: observation.summary === "ACCEPT",
      skipped: false
    })
  }

  error(err) {
    this.karma.error(err)
  }

  finish() {
    this.karma.complete()
  }
}