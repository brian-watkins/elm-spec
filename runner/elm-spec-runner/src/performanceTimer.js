const { performance } = require('perf_hooks')

module.exports = class PerformanceTimer {
  start() {
    this.startTime = performance.now()
  }

  stop() {
    this.stopTime = performance.now()
  }

  getTime() {
    return this.stopTime - this.startTime
  }
}