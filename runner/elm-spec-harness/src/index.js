const HarnessController = require('./controller')

const harnessController = new HarnessController()

function prepareHarness(name) {
  return harnessController.prepareHarness(name)
}

function onObservation(handler) {
  harnessController.setObservationHandler(handler)
}

function onLog(handler) {
  harnessController.setLogHandler(handler)
}

module.exports = {
  prepareHarness,
  onObservation,
  onLog
}