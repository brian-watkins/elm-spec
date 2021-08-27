const ElmContext = require('elm-spec-core/src/elmContext')
const HarnessController = require('elm-spec-core/src/harness/controller')

const base = document.createElement("base")
base.setAttribute("href", "http://elm-spec")
window.document.head.appendChild(base)

const elmContext = new ElmContext(window)

window._elm_spec.harnessController = new HarnessController(elmContext)