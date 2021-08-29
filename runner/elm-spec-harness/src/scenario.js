module.exports = class HarnessScenario {
  constructor(context, runner, sendToProgram) {
    this.context = context
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
      this.runner.once("observation", function (obs) {
        observation = obs
      })
      this.runner.once("complete", function () {
        theRunner.removeAllListeners("error")
        this.context.get("harnessObservationHandler")(observation, handlerData)
        resolve(observation)
      })
      this.runner.once("error", function (report) {
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
    const theRunner = this.runner
    return new Promise((resolve, reject) => {
      let observation = null
      this.runner.once("complete", () => {
        if (observation) {
          this.context.get("harnessObservationHandler")(observation)
        }
        resolve()
      })
      this.runner.once("observation", (obs) => {
        observation = obs
      })
      this.runner.once("error", (report) => {
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
    }).then((value) => {
      theRunner.removeAllListeners("complete")
      theRunner.removeAllListeners("observation")
      theRunner.removeAllListeners("error")
      return value
    })
  }
}

