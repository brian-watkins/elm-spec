module.exports = class PortPlugin {
  constructor(app) {
    this.app = app
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
        this.app.ports[port.cmd].subscribe((commandValue) => {
          const record = {
            home: "_port",
            name: "received",
            body: {
              name: port.cmd,
              value: commandValue
            }
          }
          this.app.ports.sendIn.send(record)
        })
    }
  }
}
