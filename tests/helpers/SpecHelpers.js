const chai = require('chai')
const expect = chai.expect


exports.isForRealBrowser = () => {
  return process.env.ELM_SPEC_CONTEXT === "browser"
}

exports.runInContext = (runner) => {
  if (this.isForRealBrowser()) {
    return page.evaluate((fun) => {
      return eval(fun)(window)
    }, runner.toString())
  } else {
    return runner(page.window)
  }
}

exports.expectPassingSpec = (specProgram, specName, done, matcher) => {
  this.expectSpec(specProgram, specName, done, (observations) => {
    for (let i = 0; i < observations.length; i++) {
      this.expectAccepted(observations[i])
    }
    if (matcher) matcher(observations)
  })
}

exports.expectSpec = (specProgram, specName, done, matcher, options) => {
  if (this.isForRealBrowser()) {
    runSpecInBrowser(specProgram, specName, done, matcher, options)
  } else {
    runSpecInJsdom(specProgram, specName, done, matcher, options)
  }
}

exports.expectProgram = (specProgram, done, matcher) => {
  this.expectProgramAtVersion(specProgram, null, done, matcher)
}

exports.expectProgramAtVersion = (specProgram, version, done, matcher) => {
  if (this.isForRealBrowser()) {
    runProgramInBrowser(specProgram, version, done, matcher)
  } else {
    runProgramInJsdom(specProgram, version, done, matcher)
  }
}

exports.expectAccepted = (observation) => {
  if (observation) {
    expect(observation.summary).to.equal("ACCEPT", `Rejected: ${JSON.stringify(observation.report)}`)
  } else {
    expect.fail("observation is null!")
  }
}

exports.expectRejected = (observation, report) => {
  expect(observation.summary).to.equal("REJECT")
  expect(observation.report).to.deep.equal(report)
}

exports.reportLine = (statement, detail = null) => ({
  statement,
  detail
})

const runProgramInJsdom = (specProgram, version, done, matcher) => {
  page.window._elm_spec.runProgram(specProgram, version)
    .then(({ observations, error }) => {
      matcher(observations, error)
      done()
    }).catch((err) => {
      if (err.name === "AssertionError") {
        done(err)
      } else {
        console.log("Error running program in JSDOM", err)
        process.exit(1)
      }
    })
}

const runProgramInBrowser = (specProgram, version, done, matcher) => {
  page.evaluate(({ program, version }) => {
    return _elm_spec.runProgram(program, version)
  }, { program: specProgram, version }).then(({ observations, error }) => {
    matcher(observations, error)
    done()
  }).catch((err) => {
    if (err.name === "AssertionError") {
      done(err)
    } else {
      console.log("Error running program in browser", err)
      process.exit(1)
    }
  })
}

const runSpecInBrowser = (specProgram, specName, done, matcher, options) => {
  page.evaluate(({ program, name, options }) => {
    return _elm_spec.runSpec(program, name, options)
  }, { program: specProgram, name: specName, options }).then(({ observations, error, logs }) => {
    matcher(observations, error, logs)
    done()
  }).catch((err) => {
    if (err.name === "AssertionError") {
      done(err)
    } else {
      console.log("Error running spec in browser", err)
      process.exit(1)
    }
  })
}

const runSpecInJsdom = (specProgram, specName, done, matcher, options) => {
  page.window._elm_spec.runSpec(specProgram, specName, options)
    .then(({ observations, error, logs }) => {
      matcher(observations, error, logs)
      done()
    })
    .catch((err) => {
      if (err.name === "AssertionError") {
        done(err)
      } else {
        console.log("Error running spec in JSDOM", err)
        process.exit(1)
      }
    })
}
