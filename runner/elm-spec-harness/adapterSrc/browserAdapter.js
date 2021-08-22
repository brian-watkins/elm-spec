const ElmContext = require('elm-spec-core/src/elmContext')
const HarnessRunner = require('elm-spec-core/src/harnessRunner')
const ProgramReference = require('elm-spec-core/src/programReference')
const { createProxyApp } = require('./ProxyApp')

const base = document.createElement("base")
base.setAttribute("href", "http://elm-spec")
window.document.head.appendChild(base)

const elmContext = new ElmContext(window)

window._elm_spec.observationHandler = (observation) => {
  // do nothing by default
}

window._elm_spec.startHarness = (name) => {
  const programReferences = ProgramReference.findAll(Elm)

  const programReference = programReferences.find((ref) => ref.moduleName.join(".") === name)

  if (programReference === undefined) {
    throw new Error(`Module ${name} does not exist!`)
  }

  const program = programReference.program

  app = program.init({
    flags: {}
  })

  // then call the program runner with the app
  const runner = new HarnessRunner(app, elmContext, {})
  runner
    .on("log", (report) => {
      console.log("Log", report)
    })
    .run()

  const sendToProgram = elmContext.sendToProgram()

  const proxyApp = createProxyApp(app)

  return {
    getElmApp: () => proxyApp,
    start: async (name, config = null) => {
      elmContext.timer.reset()
      return new Promise((resolve, reject) => {
        runner.once("complete", () => {
          runner.removeAllListeners("error")
          resolve()
        })
        runner.once("error", report => {
          runner.removeAllListeners("complete")
          reject(report[0].statement)
        })
        sendToProgram({
          home: "_harness",
          name: "start",
          body: {
            setup: name,
            config
          }
        })
      })
    },
    stop: () => {
      proxyApp.resetPorts()
    },
    wait: async () => {
      return new Promise((resolve) => {
        runner.once("complete", resolve)
        sendToProgram({
          home: "_harness",
          name: "wait",
          body: null
        })
      })
    },
    observe: async (name, expected, handlerData) => {
      return new Promise((resolve) => {
        let observation
        runner.once("observation", function(obs) {
          observation = obs
        })
        runner.once("complete", function() {
          window._elm_spec.observationHandler(observation, handlerData)
          resolve(observation)
        })
        sendToProgram({
          home: "_harness",
          name: "observe",
          body: {
            observer: name,
            expected
          }
        })
      })
    },
    runSteps: async (name, config = null) => {
      return new Promise((resolve) => {
        runner.once("complete", resolve)
        sendToProgram({
          home: "_harness",
          name: "run",
          body: {
            steps: name,
            config
          }
        })
      })
    }
  }
}
