const BrowserContext = require('../../runner/karma-elm-spec-framework/src/browserContext')
const SuiteRunner = require('elm-spec-core/src/suiteRunner')
const ProgramRunner = require('elm-spec-core/src/programRunner')
const TestReporter = require('./testReporter')

const context = new BrowserContext(window, [])

const base = document.createElement("base")
base.setAttribute("href", "http://localhost")
window.document.head.appendChild(base)


window._elm_spec.runProgram = (specProgram, version) => {
  return new Promise((resolve, reject) => {
    if (!window.Elm) {
      reject("Elm not compiled?!")
    }

    const program = Elm.Specs[specProgram]
    const reporter = new TestReporter()
    const options = {
      tags: [],
      endOnFailure: false,
      timeout: 500
    }
    
    new SuiteRunner(context, reporter, options, version)
      .on('complete', () => {
        resolve({
          observations: reporter.observations,
          error: reporter.specError
        })
      })
      .run([program])
  })
}

window._elm_spec.runSpec = (specProgram, specName, options) => {
  if (!window.Elm) {
    throw Error('Elm not compiled?!')
  }

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
  let error = null

  new ProgramRunner(app, context, options || { tags: [], endOnFailure: false, timeout: 2000 })
      .on('observation', (observation) => {
        observations.push(observation)
      })
      .on('complete', () => {
        resolve({ observations, error })
      })
      .on('finished', () => {
        resolve({ observations, error })
      })
      .on('error', (err) => {
        error = err
      })
      .run()
}