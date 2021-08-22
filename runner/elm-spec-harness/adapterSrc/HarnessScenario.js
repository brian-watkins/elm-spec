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
    return new Promise((resolve, reject) => {
      let theRunner = this.runner
      let observation
      this.runner.once("observation", function(obs) {
        observation = obs
      })
      this.runner.once("complete", function() {
        theRunner.removeAllListeners("error")
        window._elm_spec.observationHandler(observation, handlerData)
        resolve(observation)
      })
      this.runner.once("error", function(report) {
        theRunner.removeAllListeners("observation")
        theRunner.removeAllListeners("complete")
        reject(report[0].statement)
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
      const theRunner = this.runner
      this.runner.once("complete", () => {
        theRunner.removeAllListeners("error")
        resolve()
      })
      this.runner.once("error", (report) => {
        theRunner.removeAllListeners("complete")
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