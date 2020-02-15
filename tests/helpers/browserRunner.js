const { SuiteRunner, ProgramRunner, ElmContext } = require('elm-spec-core')
const ProgramReference = require('../../runner/elm-spec-core/src/programReference')
const TestReporter = require('./testReporter')

const elmContext = new ElmContext(window)

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
    throw Error('Elm not compiled?!')
  }

  elmContext.clock.reset()
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

  new ProgramRunner(app, context, options || { tags: [], endOnFailure: false })
      .on('observation', (observation) => {
        observations.push(observation)
      })
      .on('complete', () => {
        resolve({ observations, error })
      })
      .on('error', (err) => {
        error = err
      })
      .run()
}