const SpecPlugin = require('./specPlugin')
const PortPlugin = require('./portPlugin')


exports.run = (specProgram, specName) => {
  return new Promise((resolve, reject) => {
    initSpec(specProgram, specName, resolve, reject)
  })
}

initSpec = (specProgram, specName, resolve, reject) => {
  var app = specProgram.init({
    flags: { specName }
  })

  const specPlugin = new SpecPlugin(app, resolve)
  const portPlugin = new PortPlugin(app)

  app.ports.sendOut.subscribe((specMessage) => {
    try {
      if (specMessage.home === "_spec") {
        specPlugin.handle(specMessage)
      }
      else if (specMessage.home === "_port") {
        portPlugin.handle(specMessage)
      }
    } catch (err) {
      reject(err)
    }
  })
}