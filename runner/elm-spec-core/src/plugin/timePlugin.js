const {
  setTimezoneOffset
} = require('../fakes')

module.exports = class TimePlugin {
  constructor(context) {
    this.window = context.window
    this.clock = context.clock
  }

  handle(specMessage) {
    switch (specMessage.name) {
      case "set-time": {
        this.clock.setSystemTime(specMessage.body)
        break
      }
      case "set-timezone": {
        setTimezoneOffset(this.window, specMessage.body)
        break
      }
      case "tick": {
        this.clock.tick(specMessage.body)
        break
      }
    }
  }
}