const { report, line } = require('../report')

module.exports = class PortPlugin {
  constructor(app) {
    this.app = app
    this.subscriptions = []
  }

  handle(specMessage, out, next, abort) {
    switch (specMessage.name) {
      case "send": {
        const subscription = specMessage.body
        if (this.app.ports.hasOwnProperty(subscription.sub)) {
          try {
            this.app.ports[subscription.sub].send(subscription.value)
          } catch (err) {
            abort(report(
              line(
                `A step tried to send an unexpected value through the port '${subscription.sub}'`,
                JSON.stringify(subscription.value, null, 2)
              )
            ))
          }
        } else {
          abort(report(
            line("Attempt to send message to unknown subscription", subscription.sub)
          ))
        }
        break
      }
    }
  }

  subscribe({ ignore }) {
    const portNames = Object.keys(this.app.ports)
    for (const key of portNames) {
      if (this.app.ports[key].hasOwnProperty("subscribe")) {
        if (ignore.includes(key)) continue
        this.subscribeToPort(key)
      }
    }
  }

  subscribeToPort(name) {
    const port = { cmd: name }
    port.listener = this.portListener(port)
    this.subscriptions.push(port)
    this.app.ports[port.cmd].subscribe(port.listener)
  }

  portListener(port) {
    const app = this.app
    return function (commandValue) {
      const record = {
        home: "_port",
        name: "received",
        body: {
          name: port.cmd,
          value: commandValue
        }
      }
      app.ports.elmSpecIn.send(record)
    }
  }

  unsubscribe() {
    for (let i = 0; i < this.subscriptions.length; i++) {
      const port = this.subscriptions[i]
      this.app.ports[port.cmd].unsubscribe(port.listener)
    }
    this.subscriptions = []
  }
}
