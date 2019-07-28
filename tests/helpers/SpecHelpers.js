const chai = require('chai')
const expect = chai.expect

exports.expectFailingSpec = (specProgram, specName, matcher, done) => {
  runSpec(specProgram, specName, (observation) => {
    if (observation.summary === "ACCEPT") {
      expect.fail("\n\n\tExpected the spec to fail but it passed\n")
    }
    expect(observation.summary).to.equal("REJECT")
    matcher(observation.message)
  }, done)
}

exports.expectPassingSpec = (specProgram, specName, done) => {
  runSpec(specProgram, specName, (observation) => {
    if (observation.summary === "REJECT") {
      expect.fail("\n\n\tExpected the spec to pass but got this failure message:\n\n\t" + observation.message + "\n")
    }
    expect(observation.summary).to.equal("ACCEPT")
    expect(observation.message).to.be.null
  }, done)
}

const runSpec = (specProgram, specName, matcher, done) => {
  var app = specProgram.init({
    flags: { specName }
  })

  app.ports.sendOut.subscribe((specMessage) => {
    try {
      if (specMessage.home === "spec") {
        const state = specMessage.body
        if (state == "STEP_COMPLETE") {
          setTimeout(() => {
            app.ports.sendIn.send({ home: "spec", body: "NEXT_STEP" })
          }, 35)
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
        const observation = specMessage.body
        matcher(observation)
        done()
      }
    } catch (err) {
      done(err)
    }
  })
}