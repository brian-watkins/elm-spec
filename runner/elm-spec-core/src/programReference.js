const isProgram = (elmModule) => {
  return elmModule.init !== undefined
}

module.exports = class ProgramReference {
  static findAll(Elm, path = []) {
    return Object.entries(Elm).reduce((references, [name, elmModule]) => {
      const modulePath = path.concat([name])

      if (isProgram(elmModule)) {
        return references.concat([new ProgramReference(elmModule, modulePath)])
      } else {
        return references.concat(ProgramReference.findAll(elmModule, modulePath))
      }
    }, [])
  }

  constructor(program, path) {
    this.path = path
    this.program = program
  }
}