const ElmContext = require('elm-spec-core/src/elmContext')
const ProgramReference = require('elm-spec-core/src/programReference')
const Harness = require('./harness')
const HarnessRunner = require('./runner')
const { createProxyApp } = require('./proxyApp')

module.exports = class HarnessController {
  constructor() {
    this.context = new ElmContext(window)
  }

  prepareHarness(moduleName, version) {
    const harnessApp = this.context.evaluate((Elm) => {
      if (!Elm) {
        return undefined
      }

      return this.initHarnessProgram(Elm, moduleName, version || HarnessRunner.version())
    })
    
    if (!harnessApp) {
      throw new Error("Compilation error!")
    }

    const runner = new HarnessRunner(harnessApp, this.context, {})
    runner
      .on("log", (report) => {
        this.logHandler(report)
      })
      .on("observation", (observation) => {
        this.observationHandler(observation)
      })
      .subscribe()

    const proxyApp = createProxyApp(harnessApp)

    return new Harness(this.context, runner, proxyApp)
  }

  initHarnessProgram(Elm, moduleName, version) {
    const programReference = ProgramReference.find(Elm, moduleName)

    if (programReference === undefined) {
      throw new Error(`Module ${moduleName} does not exist!`)
    }

    const program = programReference.program

    return program.init({
      flags: {
        version
      }
    })
  }

  setObservationHandler(handler) {
    this.observationHandler = handler
  }

  setLogHandler(handler) {
    this.logHandler = handler
  }
}