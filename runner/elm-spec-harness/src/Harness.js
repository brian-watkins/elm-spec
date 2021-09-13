const HarnessScenario = require('./scenario')
const { writeReport } = require('./report')

module.exports = class Harness {

  constructor(context, runner, proxyApp) {
    this.context = context
    this.runner = runner
    this.proxyApp = proxyApp
  }

  getElmApp() {
    return this.proxyApp
  }

  async startScenario(name, config = null) {
    return new Promise((resolve, reject) => {
      this.runner.once("complete", () => {
        const scenario = new HarnessScenario(this.context, this.runner)
        resolve(scenario)
      })
      this.runner.once("error", report => {
        reject(new Error(writeReport(report)))
      })
      this.context.sendToProgram({
        home: "_harness",
        name: "start",
        body: {
          setup: name,
          config
        }
      })
    })
    .finally(() => {
      this.runner.removeAllListeners("error")
      this.runner.removeAllListeners("complete")
    })
  }

  stopScenario() {
    this.proxyApp.resetPorts()
  }

}