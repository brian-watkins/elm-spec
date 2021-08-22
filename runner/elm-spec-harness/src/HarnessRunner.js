
function startHarness(name) {
  return window._elm_spec.startHarness(name)
}

function onObservation(handler) {
  window._elm_spec.observationHandler = handler
}

function onLog(handler) {
  window._elm_spec.logHandler = handler
}

module.exports = {
  startHarness,
  onObservation,
  onLog
}