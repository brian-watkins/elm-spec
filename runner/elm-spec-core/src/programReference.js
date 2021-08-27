const isProgram = (elmModule) => {
  return elmModule.init !== undefined
}

module.exports = class ProgramReference {
  static findAll(Elm, path = []) {
    return Object.entries(Elm).reduce((references, [name, elmModule]) => {
      const moduleName = path.concat([name])

      if (isProgram(elmModule)) {
        return references.concat([new ProgramReference(elmModule, moduleName)])
      } else {
        return references.concat(ProgramReference.findAll(elmModule, moduleName))
      }
    }, [])
  }

  static find(Elm, moduleName) {
    return ProgramReference.findAll(Elm)
      .find((ref) => ref.moduleName.join(".") === moduleName)
  }

  constructor(program, moduleName) {
    this.moduleName = moduleName
    this.program = program
  }
}