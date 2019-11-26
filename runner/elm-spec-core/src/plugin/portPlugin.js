module.exports = class PortPlugin {
  constructor(app) {
    this.app = app
    this.subscriptions = []
  }

  handle(specMessage, abort) {
    switch (specMessage.name) {
      case "send":
        const subscription = specMessage.body
        if (this.app.ports.hasOwnProperty(subscription.sub)) {
          this.app.ports[subscription.sub].send(subscription.value)
        } else {
          abort([{
            statement: "Attempt to send message to unknown subscription",
            detail: subscription.sub
          }])
        }
        break
      case "receive":
        const port = specMessage.body
        port.listener = this.portListener(port)
        this.subscriptions.push(port)
        this.app.ports[port.cmd].subscribe(port.listener)
    }
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
      app.ports.sendIn.send(record)
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
