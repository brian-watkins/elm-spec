const { createProxyApp } = require('./proxyApp')
const HarnessRunner = require('./runner')
const HarnessScenario = require('./scenario')

module.exports = class Harness {

  constructor(context, harnessApp) {
    this.context = context
    this.runner = new HarnessRunner(harnessApp, context, {})
      
    this.runner.on("log", (report) => {
      this.context.get("harnessLogHandler")(report)
    })
      .subscribe()

    this.proxyApp = createProxyApp(harnessApp)
  }

  getElmApp() {
    return this.proxyApp
  }

  async startScenario(name, config = null) {
    const sendToProgram = this.context.sendToProgram()
    this.context.timer.reset()

    return new Promise((resolve, reject) => {
      this.runner.once("complete", () => {
        this.runner.removeAllListeners("error")
        resolve(new HarnessScenario(this.context, this.runner, sendToProgram))
      })
      this.runner.once("error", report => {
        this.runner.removeAllListeners("complete")
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
  }

  stopScenario() {
    this.proxyApp.resetPorts()
  }

}