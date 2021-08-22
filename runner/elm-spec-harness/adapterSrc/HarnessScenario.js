module.exports = class HarnessScenario {
  constructor (runner, sendToProgram) {
    this.runner = runner
    this.sendToProgram = sendToProgram
  }

  wait() {
    return new Promise((resolve) => {
      this.runner.once("complete", resolve)
      this.sendToProgram({
        home: "_harness",
        name: "wait",
        body: null
      })
    })
  }

  observe(name, expected, handlerData) {
    return new Promise((resolve) => {
      let observation
      this.runner.once("observation", function(obs) {
        observation = obs
      })
      this.runner.once("complete", function() {
        window._elm_spec.observationHandler(observation, handlerData)
        resolve(observation)
      })
      this.sendToProgram({
        home: "_harness",
        name: "observe",
        body: {
          observer: name,
          expected
        }
      })
    })
  }
  
  runSteps(name, config = null) {
    return new Promise((resolve, reject) => {
      this.runner.once("complete", () => {
        this.runner.removeAllListeners("error")
        resolve()
      })
      this.runner.once("error", (report) => {
        this.runner.removeAllListeners("complete")
        reject(report[0].statement)
      })
      this.sendToProgram({
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