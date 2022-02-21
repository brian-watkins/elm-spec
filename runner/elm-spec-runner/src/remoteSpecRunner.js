const chalk = require('chalk');
const SpecServer = require("./specServer")

module.exports = class RemoteSpecRunner {
  constructor(fileLoader) {
    this.fileLoader = fileLoader
  }

  async start(options) {
    this.specServer = new SpecServer(this.fileLoader, options)

    this.specServer.onConnect(() => {
      this.specServer.send({
        action: "run-specs",
        options: this.runOptions
      })
    })

    this.specServer.onEvent((event) => this.handleEvent(event))

    this.specServer.onRequestSpecs(() => {
      return this.compiledSpecs
    })

    return this.specServer.start("127.0.0.1")
  }

  handleEvent(event) {
    switch (event.action) {
      case "reporter_start":
        this.reporter.startSuite()
        break
      case "reporter_observe":
        this.reporter.record(event.observation)
        break
      case "reporter_log":
        this.reporter.log(event.report)
        break
      case "reporter_error":
        this.reporter.error(event.error)
        break
      case "reporter_finished":
        this.reporter.finish()
        break
      case "specs-finished":
        this.specsFinished([event.results])
        break
    }
  }

  async run(runOptions, compiledSpecs, reporter) {
    this.runOptions = runOptions
    this.runOptions.parallelSegments = 1
    this.compiledSpecs = compiledSpecs
    this.reporter = reporter

    if (this.specServer.isConnected()) {
      this.specServer.send({
        action: "reload-specs"
      })
    } else {
      this.reporter.info(`Visit ${chalk.cyan(this.specsURL())} to run your specs!`)
    }

    return new Promise((resolve) => {
      this.specsFinished = resolve
    })
  }

  specsURL() {
    const host = this.specServer.host()
    return `${host}/specs/`
  }

  async stop() {
    this.specServer.send({
      action: "close"
    })

    this.specServer.stop()
  }
}
