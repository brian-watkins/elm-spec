const chai = require('chai')
const expect = chai.expect
const { SuiteRunner, ProgramRunner, Compiler } = require('elm-spec-core')
const ProgramReference = require('../../runner/elm-spec-core/src/programReference')
const { loadElmContext } = require('../../runner/elm-spec-runner/src/jsdomContext')
const TestReporter = require('./testReporter')
const path = require('path')


const elmSpecContext = process.env.ELM_SPEC_CONTEXT

exports.runInContext = (runner) => {
  if (elmSpecContext === "jsdom") {
    prepareJsdom()
    return runner(elmContext.window)
  } else if (elmSpecContext === "browser") {
    return page.evaluate((fun) => {
      return eval(fun)(window)
    }, runner.toString())
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
  if (elmSpecContext === "jsdom") {
    runSpecInJsdom(specProgram, specName, done, matcher, options)
  } else if (elmSpecContext === "browser") {
    runSpecInBrowser(specProgram, specName, done, matcher, options)
  }
}

exports.expectProgram = (specProgram, done, matcher) => {
  this.expectProgramAtVersion(specProgram, null, done, matcher)
}

exports.expectProgramAtVersion = (specProgram, version, done, matcher) => {
  if (elmSpecContext === "jsdom") {
    runProgramInJsdom(specProgram, version, done, matcher)
  } else if (elmSpecContext === "browser") {
    runProgramInBrowser(specProgram, version, done, matcher)
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

let elmContext = null

const prepareJsdom = () => {
  if (!elmContext) {
    const specSrcDir = path.join(__dirname, "..", "src")

    const compiler = new Compiler({
      cwd: specSrcDir,
      specPath: "./Specs/*Spec.elm"
    })

    elmContext = loadElmContext(compiler)
  }
}

const runProgramInJsdom = (specProgram, version, done, matcher) => {
  prepareJsdom()

  elmContext.evaluate((Elm) => {
    if (!Elm) process.exit(1)

    const program = Elm.Specs[specProgram]
    const reporter = new TestReporter()
    const options = {
      tags: [],
      endOnFailure: false
    }

    new SuiteRunner(elmContext, reporter, options, version)
      .on('complete', () => {
        setTimeout(() => {
          matcher(reporter.observations, reporter.specError)
          done()
        }, 0)
      })
      .run([new ProgramReference(program, ['Specs', specProgram])])
  })
}

const runProgramInBrowser = (specProgram, version, done, matcher) => {
  page.evaluate((program, version) => {
    return _elm_spec.runProgram(program, version)
  }, specProgram, version).then(({ observations, error }) => {
    matcher(observations, error)
    done()
  }).catch((err) => {
    if (err.name === "AssertionError") {
      done(err)
    } else {
      process.exit(1)
    }
  })
}

const runSpecInBrowser = (specProgram, specName, done, matcher, options) => {  
  page.evaluate((program, name, options) => { 
    return _elm_spec.runSpec(program, name, options)
  }, specProgram, specName, options).then(({ observations, error, logs }) => {
    matcher(observations, error, logs)
    done()
  }).catch((err) => {
    if (err.name === "AssertionError") {
      done(err)
    } else {
      process.exit(1)
    }
  })
}

const runSpecInJsdom = (specProgram, specName, done, matcher, options) => {
  prepareJsdom()

  elmContext.evaluate((Elm) => {
    if (!Elm) process.exit(1)
    
    elmContext.clock.reset()
    var app = Elm.Specs[specProgram].init({
      flags: { specName }
    })
  
    runSpec(app, elmContext, done, matcher, options)
  })
}

const runSpec = (app, context, done, matcher, options) => {
  const observations = []
  let error = null
  let logs = []
  const programOptions = options || {}

  new ProgramRunner(app, context, programOptions)
    .on('observation', (observation) => {
      observations.push(observation)
    })
    .on('complete', () => {
      try {
        matcher(observations, error, logs)
        done()
      } catch (err) {
        done(err)
      }
    })
    .on('error', (err) => {
      error = err
    })
    .on('log', (report) => {
      logs.push(report)
    })
    .run()
}
