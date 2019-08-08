
exports.run = (specProgram, specName) => {
  return new Promise((resolve, reject) => {
    initSpec(specProgram, specName, resolve, reject)
  })
}

initSpec = (specProgram, specName, resolve, reject) => {
  var app = specProgram.init({
    flags: { specName }
  })

  let timer = null;
  let observations = []

  app.ports.sendOut.subscribe((specMessage) => {
    try {
      if (specMessage.home === "spec") {
        const state = specMessage.body
        if (state == "STEP_COMPLETE") {
          if (timer) clearTimeout(timer)
          timer = setTimeout(() => {
            app.ports.sendIn.send({ home: "spec", body: "NEXT_STEP" })
          }, 1)
        }
        else if (state === "SPEC_COMPLETE") {
          resolve(observations)
        }
      }
      else if (specMessage.home === "spec-send") {
        const subscription = specMessage.body
        app.ports[subscription.sub].send(subscription.value)
      }
      else if (specMessage.home === "spec-receive") {
        const port = specMessage.body
        app.ports[port.cmd].subscribe((commandMessage) => {
          app.ports.sendIn.send({ home: "spec-receive", body: commandMessage })
        })
      }
      else if (specMessage.home === "spec-observation") {
        observations.push(specMessage.body)
      }
    } catch (err) {
      reject(err)
    }
  })
}