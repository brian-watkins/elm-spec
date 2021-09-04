const { writeReport } = require('./report')

module.exports = class HarnessScenario {
  constructor(context, runner) {
    this.context = context
    this.runner = runner
  }

  wait() {
    return new Promise((resolve) => {
      this.runner.once("complete", resolve)
      this.context.sendToProgram({
        home: "_harness",
        name: "wait",
        body: null
      })
    })
  }

  observe(name, expected, description = "") {
    return this.waitForComplete({
      home: "_harness",
      name: "observe",
      body: {
        observer: name,
        expected,
        description
      }
    })
  }

  runSteps(name, config = null) {
    return this.waitForComplete({
      home: "_harness",
      name: "run",
      body: {
        steps: name,
        config
      }
    })
  }

  waitForComplete(message) {
    return new Promise((resolve, reject) => {
      this.runner.once("complete", () => {
        resolve()
      })
      this.runner.once("error", (report) => {
        reject(writeReport(report))
      })
      this.context.sendToProgram(message)
    }).finally(() => {
      this.runner.removeAllListeners("complete")
      this.runner.removeAllListeners("error")
    })
  }
}

