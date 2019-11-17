
module.exports = class TimePlugin {
  constructor(clock, window) {
    this.window = window
    this.nativeSetTimeout = setTimeout.bind(window)
    this.nativeSetInterval = setInterval.bind(window)
    this.clock = clock
    this.timeouts = []
    this.intervals = []
  }

  handle(specMessage, next) {
    switch (specMessage.name) {
      case "setup":
        this.window.setTimeout = (fun, delay) => {
          if (delay === 0) {
            return this.nativeSetTimeout(fun, 0)
          }

          const id = this.clock.setTimeout(fun, delay)
          this.timeouts.push(id)
          return id
        }

        this.window.setInterval = (fun, delay) => {
          const id = this.clock.setInterval(fun, delay)
          this.intervals.push(id)
          return id
        }

        break
      case "tick": {
        this.clock.tick(specMessage.body)
        next()
        break
      }
    }
  }

  clearTimers() {
    this.clock.runToFrame()
    
    for (let i = 0; i < this.timeouts.length; i++) {
      this.clock.clearTimeout(this.timeouts[i])
    }

    for (let i = 0; i < this.intervals.length; i++) {
      this.clock.clearInterval(this.intervals[i])
    }

    this.resetFakes()
  }

  resetFakes() {
    this.window.setTimeout = this.nativeSetTimeout
    this.window.setInterval = this.nativeSetInterval
  }
}