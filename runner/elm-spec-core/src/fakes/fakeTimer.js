module.exports = class FakeTimer {
  constructor (clock) {
    this.clock = clock
  }

  fakeSetTimeout() {
    return (fun, delay) => {
      if (delay === 0) {
        return this.addToStack(fun)
      }
      
      return this.clock.setTimeout(fun, delay)
    }
  }

  fakeSetInterval() {
    return (fun, period) => {
      return this.clock.setInterval(fun, period)
    }
  }

  runAllAnimationFrameTasks() {
    this.clock.runToFrame()
  }

  currentAnimationFrameTasks() {
    return Object.values(this.clock.timers)
      .filter(t => t.animation)
  }

  triggerAnimationFrameTask(id) {
    const timer = this.clock.timers[id]
    timer.func.apply(null, timer.args);
    this.clock.cancelAnimationFrame(id)
  }

  clearTimers() {
    Object.values(this.clock.timers)
      .filter(t => t.type === "Timeout")
      .forEach(t => {
        this.clock.clearTimeout(t.id)
      })

    Object.values(this.clock.timers)
      .filter(t => t.type === "Interval")
      .forEach(t => {
        this.clock.clearInterval(t.id)
      })
  }

  reset() {
    this.clock.reset()
  }

  addToStack(fun) {
    if (this.stackTimeout) {
      // Note: This seems weird but Elm never actually calls clearTimeout so
      // as long as ordering doesn't matter then this should be ok. Speeds up the test run.
      // Otherwise, need to reset the stackTimeout function each time this is called.
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