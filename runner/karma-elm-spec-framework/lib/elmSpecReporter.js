
var ElmSpecReporter = function (baseReporterDecorator, formatError, config) {
  baseReporterDecorator(this);

  var self = this;

  function specComplete(browser, result) {
    if (!result.success) {
      self.write("Spec failed!", result)
    }
  }

  self.onSpecComplete = function (browser, result) {
    specComplete(browser, result);
  };
}

ElmSpecReporter.$inject = ['baseReporterDecorator', 'formatError', 'config'];

module.exports = {
  ElmSpecReporter
}