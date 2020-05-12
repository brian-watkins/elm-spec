const SuiteRunner = require('elm-spec-core/src/suiteRunner')
const ProgramRunner = require('elm-spec-core/src/programRunner')
const ElmContext = require('elm-spec-core/src/elmContext')
const ProgramReference = require('elm-spec-core/src/programReference')
const TestReporter = require('./testReporter')

const elmContext = new ElmContext(window)

const base = document.createElement("base")
base.setAttribute("href", "http://localhost")
window.document.head.appendChild(base)

const css = document.createElement("style")
css.type = 'text/css';
css.innerHTML = 'body { margin: 0px; padding: 0px; }';
window.document.head.appendChild(css)

window._elm_spec.runProgram = (specProgram, version) => {
  return new Promise((resolve, reject) => {
    if (!window.Elm) {
      return Promise.reject("Elm not compiled!")
    }

    const program = Elm.Specs[specProgram]
    const reporter = new TestReporter()
    const options = {
      endOnFailure: false
    }
    
    new SuiteRunner(elmContext, reporter, options, version)
      .on('complete', () => {
        resolve({
          observations: reporter.observations,
          error: reporter.specError
        })
      })
      .run([new ProgramReference(program, ['Specs', specProgram])])
  })
}

window._elm_spec.runSpec = (specProgram, specName, options) => {
  if (!window.Elm) {
    return Promise.reject("Elm not compiled!")
  }

  elmContext.timer.reset()
  var app = Elm.Specs[specProgram].init({
    flags: { specName }
  })

  return new Promise((resolve, reject) => {
    runProgram(app, elmContext, options, resolve, reject)
  })
}

const runProgram = (app, context, options, resolve, reject) => {
  const observations = []
  let error = null
  let logs = []

  new ProgramRunner(app, context, options || { endOnFailure: false })
      .on('observation', (observation) => {
        observations.push(observation)
      })
      .on('complete', () => {
        resolve({ observations, error, logs })
      })
      .on('log', (report) => {
        logs.push(report)
      })
      .on('error', (err) => {
        error = err
      })
      .run()
}