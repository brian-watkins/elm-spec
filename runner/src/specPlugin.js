module.exports = class SpecPlugin {
  constructor(app, resolve) {
    this.app = app;
    this.timer = null;
    this.observations = []
    this.resolve = resolve
  }

  handle(specMessage) {
    if (specMessage.name === "state") {
      const state = specMessage.body
      if (state == "STEP_COMPLETE") {
        if (this.timer) clearTimeout(this.timer)
        this.timer = setTimeout(() => {
          this.app.ports.sendIn.send({ home: "_spec", name: "state", body: "NEXT_STEP" })
        }, 1)
      }
      else if (state === "SPEC_COMPLETE") {
        this.resolve(this.observations)
      }  
    }
    else if (specMessage.name === "observation") {
      this.observations.push(specMessage.body)
    }
  }
}
