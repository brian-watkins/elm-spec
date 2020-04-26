module.exports = class FakeTimer {
  constructor (clock) {
    this.clock = clock
    this.timeouts = []
    this.intervals = []
  }

  fakeSetTimeout() {
    return (fun, delay) => {
      if (delay === 0) {
        return this.addToStack(fun)
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

  addToStack(fun) {
    if (this.stackTimeout) {
      // Note: This seems weird but Elm never actually calls clearTimeout so
      // as long as ordering doesn't matter then this should be ok. Speeds up the test run.
      // Otherwise, need to reset the stackTimeout function each time this is called.
      // This probably works because these are functions queued only between the start of a
      // step and the first pass through the program's update function.
      fun()
      return -1
    } else {
      return setTimeout(fun, 0)
    }
  }

  whenStackIsComplete(andThen) {
      this.stopWaitingForStack()
      this.stackTimeout = setTimeout(() => {
        this.stackTimeout = null
        andThen()
      }, 0)
  }

  stopWaitingForStack() {
    if (this.stackTimeout) {
      clearTimeout(this.stackTimeout)
      this.stackTimeout = null
    }
  }
}