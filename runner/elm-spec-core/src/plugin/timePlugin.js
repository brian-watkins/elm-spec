module.exports = class TimePlugin {
  constructor(context) {
    this.context = context
    this.clock = context.timer.clock
  }

  handle(specMessage) {
    switch (specMessage.name) {
      case "set-time": {
        this.clock.setSystemTime(specMessage.body)
        break
      }
      case "set-timezone": {
        this.context.setTimezoneOffset(specMessage.body)
        break
      }
      case "tick": {
        this.clock.tick(specMessage.body)
        break
      }
    }
  }
}