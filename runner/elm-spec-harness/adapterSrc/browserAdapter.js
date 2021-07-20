const ElmContext = require('elm-spec-core/src/elmContext')
const ProgramRunner = require('elm-spec-core/src/programRunner')
const ProgramReference = require('elm-spec-core/src/programReference')


const base = document.createElement("base")
base.setAttribute("href", "http://elm-spec")
window.document.head.appendChild(base)

const elmContext = new ElmContext(window)

window._elm_spec.startHarness = (options) => {
  // Maybe we need to specify which harness to run somehow?
  const programReferences = ProgramReference.findAll(Elm)

  // here we need to initialize the harness program
  const program = programReferences[0].program
  app = program.init({
    flags: {}
  })

  // then call the program runner with the app
  const runner = new ProgramRunner(app, elmContext, {})
  runner
    .on("complete", (shouldContinue) => {
      console.log("Complete!")
    })
    .on("error", (error) => {
      console.log("Error", error)
    })
    .on("log", (report) => {
      console.log("Log", report)
    })
    .run()

  return {
    observe: async (name, expected) => {
      console.log("Observing", name, expected)
      return new Promise((resolve) => {
        runner.on("observation", function(obs) {
          resolve(obs)
        })
        elmContext.sendToProgram({
          home: "_harness",
          name: "observe",
          body: {
            observer: name,
            expected
          }
        })
      })
    }
  }
}
