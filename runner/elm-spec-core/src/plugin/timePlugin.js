
module.exports = class TimePlugin {
  constructor(clock, window) {
    this.window = window
    this.clock = clock
    this.timeouts = []
    this.intervals = []

    this.nativeSetTimeout = setTimeout.bind(window)
    this.window.setTimeout = (fun, delay) => {
      if (delay === 0) {
        return this.nativeSetTimeout(fun, 0)
      }

      const id = this.clock.setTimeout(fun, delay)
      this.timeouts.push(id)
      return id
    }

    this.nativeSetInterval = setInterval.bind(window)
    this.window.setInterval = (fun, delay) => {
      const id = this.clock.setInterval(fun, delay)
      this.intervals.push(id)
      return id
    }
  }

  handle(specMessage, next) {
    switch (specMessage.name) {
      case "set-time": {
        this.clock.setSystemTime(specMessage.body)
        break
      }
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
  }

  resetFakes() {
    this.window.setTimeout = this.nativeSetTimeout
    this.window.setInterval = this.nativeSetInterval
  }
}