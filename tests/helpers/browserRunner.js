const BrowserContext = require('../../runner/karma-elm-spec-framework/src/browserContext')
const HtmlPlugin = require('elm-spec-core/src/plugin/htmlPlugin')
const HttpPlugin = require('elm-spec-core/src/plugin/httpPlugin')
const ProgramRunner = require('elm-spec-core/src/programRunner')

const context = new BrowserContext(window, [])

const base = document.createElement("base")
base.setAttribute("href", "http://localhost")
window.document.head.appendChild(base)


window._elm_spec.runProgram = (specProgram, options) => {
  return new Promise((resolve, reject) => {
    context.evaluateProgram(Elm.Specs[specProgram], (app, plugins) => {
      runProgram(app, context, plugins, options, resolve, reject)
    })
  })
}

window._elm_spec.runSpec = (specProgram, specName, options) => {
  const plugins = {
    "_html": new HtmlPlugin(context, window),
    "_http": new HttpPlugin(window)
  }

  var app = Elm.Specs[specProgram].init({
    flags: { specName }
  })

  return new Promise((resolve, reject) => {
    runProgram(app, context, plugins, options, resolve, reject)
  })
}

const runProgram = (app, context, plugins, options, resolve, reject) => {
  const observations = []
  new ProgramRunner(app, context, plugins, options || { timeout: 2000 })
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