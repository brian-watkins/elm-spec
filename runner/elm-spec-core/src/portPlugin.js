module.exports = class PortPlugin {
  constructor(app) {
    this.app = app
  }

  handle(specMessage) {
    switch (specMessage.name) {
      case "send":
        const subscription = specMessage.body
        this.app.ports[subscription.sub].send(subscription.value)
        break
      case "receive":
        const port = specMessage.body
        this.app.ports[port.cmd].subscribe((commandMessage) => {
          this.app.ports.sendIn.send({ home: "_port", name: "received", body: commandMessage })
        })
    }
  }
}
