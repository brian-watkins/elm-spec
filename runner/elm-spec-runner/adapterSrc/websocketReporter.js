module.exports = class WebSocketReporter {
  constructor(socket) {
    this.socket = socket
  }
  
  startSuite() {
    this.socket.send(JSON.stringify({
      action: "reporter_start"
    }))
  }

  record(observation) {
    this.socket.send(JSON.stringify({
      action: "reporter_observe",
      observation
    }))
  }

  log(report) {
    this.socket.send(JSON.stringify({
      action: "reporter_log",
      report
    }))
  }

  finish() {
    this.socket.send(JSON.stringify({
      action: "reporter_finished"
    }))
  }

  error(err) {
    this.socket.send(JSON.stringify({
      action: "reporter_error",
      error: err
    }))
  }
}