module.exports = class FakeTimer {
  constructor (clock) {
    this.clock = clock
    this.holds = 0
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

  resetClock(time) {
    this.clock.setSystemTime(time)

    // Note: This fixes a bug in SinonJS/FakeTimers where animation tasks
    // aren't correctly set to run in the next animation frame if the time is reset
    this.animationTasks().forEach(t => {
      t.callAt -= time % 16
    })
  }

  tick(time) {
    this.clock.tick(time)
  }

  runAllAnimationFrameTasks() {
    this.clock.runToFrame()
  }

  animationTasks() {
    return Object.values(this.clock.timers)
      .filter(t => t.animation)
  }

  animationFrameTaskCount() {
    return this.animationTasks().length
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
      clearTimeout(this.stackTimeout)
      const id = setTimeout(fun, 0)
      this.stackTimeout = setTimeout(this.nextFun, 0)
      return id
    } else {
      return setTimeout(fun, 0)
    }
  }

  whenStackIsComplete(andThen) {
      this.stopWaitingForStack()
      this.nextFun = () => {
        this.stackTimeout = null
        andThen()
      }
      this.stackTimeout = setTimeout(this.nextFun, 0)
  }

  stopWaitingForStack() {
    if (this.stackTimeout) {
      clearTimeout(this.stackTimeout)
      this.stackTimeout = null
    }
  }

  requestHold() {
    this.holds += 1
  }

  releaseHold() {
    this.holds -= 1
  }
}