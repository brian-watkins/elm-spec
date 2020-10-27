module.exports = class TimePlugin {
  constructor(context) {
    this.context = context
  }

  handle(specMessage) {
    switch (specMessage.name) {
      case "set-time": {
        this.context.timer.resetClock(specMessage.body)
        break
      }
      case "set-timezone": {
        this.context.setTimezoneOffset(specMessage.body)
        break
      }
      case "tick": {
        this.context.timer.tick(specMessage.body)
        break
      }
    }
  }
}