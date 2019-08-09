module.exports = class PortPlugin {
  constructor(app) {
    this.app = app
  }

  handle(specMessage) {
    if (specMessage.name === "send") {
      const subscription = specMessage.body
      this.app.ports[subscription.sub].send(subscription.value)  
    } else if (specMessage.name === "receive") {
      const port = specMessage.body
      this.app.ports[port.cmd].subscribe((commandMessage) => {
        this.app.ports.sendIn.send({ home: "_port", name: "receive", body: commandMessage })
      })
    }
  }
}
