module.exports = class BrowserReporter {
  startSuite() {
    _elm_spec_reporter_start()
  }

  record(observation) {
    _elm_spec_reporter_observe(observation)
  }

  log(report) {
    _elm_spec_reporter_log(report)
  }

  finish() {
    _elm_spec_reporter_finish()
  }

  error(err) {
    _elm_spec_reporter_error(err)
  }
}