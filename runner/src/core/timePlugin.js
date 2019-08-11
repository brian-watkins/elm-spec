const lolex = require('lolex')

module.exports = class TimePlugin {
  handle(specMessage) {
    switch (specMessage.name) {
      case "setup":
        this.clock = lolex.install({
          toFake: [ "setInterval" ]
        })
        break
      case "tick":
        this.clock.tick(specMessage.body)
        break
    }
  }

  reset() {
    if (this.clock) {
      this.clock.uninstall()
      this.clock = null  
    }
  }
}