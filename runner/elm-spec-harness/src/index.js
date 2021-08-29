const HarnessController = require('./controller')

const base = document.createElement("base")
base.setAttribute("href", "http://elm-spec")
window.document.head.appendChild(base)

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