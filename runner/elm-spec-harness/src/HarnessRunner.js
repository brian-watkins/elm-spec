
function prepareHarness(name) {
  return window._elm_spec.harnessController.prepareHarness(name)
}

function onObservation(handler) {
  window._elm_spec.harnessController.setObservationHandler(handler)
}

function onLog(handler) {
  window._elm_spec.harnessController.setLogHandler(handler)
}

module.exports = {
  prepareHarness,
  onObservation,
  onLog
}