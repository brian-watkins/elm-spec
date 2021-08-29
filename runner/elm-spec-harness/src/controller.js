const ElmContext = require('elm-spec-core/src/elmContext')
const ProgramReference = require('elm-spec-core/src/programReference')
const Harness = require('./harness')

module.exports = class HarnessController {
  constructor() {
    this.context = new ElmContext(window)
  }

  prepareHarness(moduleName) {    
    const harnessApp = this.context.evaluate((Elm) => {
      // what if Elm is undefined (due to compilation error?)
      return this.initHarnessProgram(Elm, moduleName)
    })
    
    return new Harness(this.context, harnessApp)
  }

  initHarnessProgram(Elm, moduleName) {
    const programReference = ProgramReference.find(Elm, moduleName)

    if (programReference === undefined) {
      throw new Error(`Module ${moduleName} does not exist!`)
    }

    const program = programReference.program

    // Need to pass in the version at some point
    return program.init({
      flags: {}
    })
  }

  setObservationHandler(handler) {
    this.context.set("harnessObservationHandler", handler)
  }

  setLogHandler(handler) {
    this.context.set("harnessLogHandler", handler)
  }
}