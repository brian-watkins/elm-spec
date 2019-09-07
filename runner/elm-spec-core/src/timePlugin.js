const lolex = require('lolex')

module.exports = class TimePlugin {
  constructor() {
    this.setTimeout = setTimeout
  }

  handle(specMessage, next) {
    switch (specMessage.name) {
      case "setup":
        global.setTimeout = (fun, delay) => {
          if (delay === 0) {
            return this.setTimeout(fun, 0)
          } else {
            return this.clock.setTimeout(fun, delay)
          }
        }

        this.clock = lolex.install({
          toFake: [ "setInterval" ]
        })
        break
      case "tick": {
        this.clock.tick(specMessage.body)
        next()
        break
      }
    }
  }

  reset() {
    if (this.clock) {
      this.clock.uninstall()
      this.clock = null  
    }
  }
}