
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
      log: observation.report || [],
      elmSpec: {
        modulePath: observation.modulePath
      },
      success: observation.summary === "ACCEPT",
      skipped: false
    })
  }

  log(report) {
    this.karma.info({type: "elm-spec", log: report})
  }

  error(err) {
    this.karma.error(err)
  }

  finish() {
    this.karma.complete()
  }
}