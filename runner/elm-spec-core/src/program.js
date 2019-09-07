
const discover = (Elm) => {
  return Object.values(Elm).reduce((programs, program) => {
    if (program.init === undefined) {
      return programs.concat(discover(program))
    } else {
      return programs.concat([program])
    }
  }, [])
}

module.exports = {
  discover
}