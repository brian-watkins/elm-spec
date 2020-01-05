module.exports = class FakeTimer {
  constructor (clock) {
    this.clock = clock
    this.timeouts = []
    this.intervals = []
  }

  fakeSetTimeout(window) {
    return (fun, delay) => {
      if (delay === 0) {
        return window.setTimeout(fun, 0)
      }
      
      const id = this.clock.setTimeout(fun, delay)
      this.timeouts.push(id)
      return id  
    }
  }

  fakeSetInterval() {
    return (fun, period) => {
      const id = this.clock.setInterval(fun, period)
      this.intervals.push(id)
      return id  
    }
  }

  clear() {
    for (let i = 0; i < this.timeouts.length; i++) {
      this.clock.clearTimeout(this.timeouts[i])
    }
    this.timeouts = []

    for (let i = 0; i < this.intervals.length; i++) {
      this.clock.clearInterval(this.intervals[i])
    }
    this.intervals = []
  }
}