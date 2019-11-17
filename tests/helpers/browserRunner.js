const BrowserContext = require('../../runner/karma-elm-spec-framework/src/browserContext')
const ProgramRunner = require('elm-spec-core/src/programRunner')

const context = new BrowserContext(window, [])

const base = document.createElement("base")
base.setAttribute("href", "http://localhost")
window.document.head.appendChild(base)


window._elm_spec.runProgram = (specProgram, options) => {
  return new Promise((resolve, reject) => {
    context.evaluateProgram(Elm.Specs[specProgram], (app) => {
      runProgram(app, context, options, resolve, reject)
    })
  })
}

window._elm_spec.runSpec = (specProgram, specName, options) => {
  context.clock.reset()
  var app = Elm.Specs[specProgram].init({
    flags: { specName }
  })

  return new Promise((resolve, reject) => {
    runProgram(app, context, options, resolve, reject)
  })
}

const runProgram = (app, context, options, resolve, reject) => {
  const observations = []
  new ProgramRunner(app, context, options || { timeout: 2000 })
      .on('observation', (observation) => {
        observations.push(observation)
      })
      .on('complete', () => {
        resolve(observations)
      })
      .on('error', (err) => {
        reject(err)
      })
      .run()
}