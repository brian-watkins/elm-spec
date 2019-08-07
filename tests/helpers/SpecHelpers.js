const chai = require('chai')
const expect = chai.expect

exports.expectFailingSpec = (specProgram, specName, done, matcher) => {
  runSpec(specProgram, specName, done, (observations) => {
    const passes = observations.filter((o) => o.summary === "ACCEPT")
    if (passes.length > 0) {
      expect.fail(`\n\n\tExpected the spec to fail but ${passes.length} passed\n`)
    }
    for (let i = 0; i < observations.length; i++) {
      expect(observations[i].summary).to.equal("REJECT")
    }
    if (matcher) {
      matcher(observations)
    }
  })
}

exports.expectPassingSpec = (specProgram, specName, done, matcher) => {
  runSpec(specProgram, specName, done, (observations) => {
    const rejections = observations.filter((o) => o.summary === "REJECT")
    if (rejections.length > 0) {
      const errors = rejections.map((o) => o.message).join("\n\n\t")
      expect.fail(`\n\n\tExpected the spec to pass but:\n\n\t${errors}\n`)
    }
    for (let i = 0; i < rejections.length; i++) {
      expect(observations[i].summary).to.equal("ACCEPT")
      expect(observations[i].message).to.be.null
    }
    if (matcher) {
      matcher(observations)
    }
  })
}

exports.expectSpec = (specProgram, specName, done, matcher) => {
  runSpec(specProgram, specName, done, matcher)
}

const runSpec = (specProgram, specName, done, matcher) => {
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
          matcher(observations)
          done()
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
      done(err)
    }
  })
}