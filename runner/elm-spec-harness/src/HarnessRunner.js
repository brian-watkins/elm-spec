
function startHarness(name) {
  return window._elm_spec.startHarness(name)
}

function onObservation(handler) {
  window._elm_spec.observationHandler = handler
}

module.exports = {
  startHarness,
  onObservation
}