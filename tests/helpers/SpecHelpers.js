const chai = require('chai')
const expect = chai.expect
const SuiteRunner = require('elm-spec-core/src/suiteRunner')
const ProgramRunner = require('elm-spec-core/src/programRunner')
const SpecCompiler = require('elm-spec-core/src/compiler')
const JsdomContext = require('../../runner/elm-spec-runner/src/jsdomContext')
const TestReporter = require('./testReporter')


const elmSpecContext = process.env.ELM_SPEC_CONTEXT

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
  if (elmSpecContext === "jsdom") {
    runProgramInJsdom(specProgram, done, matcher)
  } else if (elmSpecContext === "browser") {
    runProgramInBrowser(specProgram, done, matcher)
  }
}

exports.expectAccepted = (observation) => {
  expect(observation.summary).to.equal("ACCEPT", `Rejected: ${JSON.stringify(observation.report)}`)
}

exports.expectRejected = (observation, report) => {
  expect(observation.summary).to.equal("REJECT")
  expect(observation.report).to.deep.equal(report)
}

exports.reportLine = (statement, detail = null) => ({
  statement,
  detail
})

const compiler = new SpecCompiler({
  specPath: "./src/Specs/*Spec.elm",
  elmPath: "../node_modules/.bin/elm"
})

const testCompiler = {
  compile: () => {
    if (!this.compiledCode) {
      this.compiledCode = compiler.compile()
      return this.compiledCode
    } else {
      return this.compiledCode
    }
  }
}

let jsdomContext = null

const prepareJsdom = () => {
  if (!jsdomContext) {
    jsdomContext = new JsdomContext(testCompiler)
  }
}

const runProgramInJsdom = (specProgram, done, matcher) => {
  prepareJsdom()

  jsdomContext.evaluate((Elm) => {
    if (!Elm) process.exit(1)

    const program = Elm.Specs[specProgram]
    const reporter = new TestReporter()
    const options = {
      tags: [],
      endOnFailure: false,
      timeout: 500
    }
  
    new SuiteRunner(jsdomContext, reporter, options)
      .on('complete', () => {
        setTimeout(() => {
          matcher(reporter.observations)
          done()
        }, 0)
      })
      .run([program])
  })
}

const runProgramInBrowser = (specProgram, done, matcher) => {
  page.evaluate((program) => {
    return _elm_spec.runProgram(program)
  }, specProgram).then((observations) => {
    matcher(observations)
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
  }, specProgram, specName, options).then((observations) => {
    matcher(observations)
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

  jsdomContext.evaluate((Elm, window) => {
    if (!Elm) process.exit(1)
    
    jsdomContext.clock.reset()
    var app = Elm.Specs[specProgram].init({
      flags: { specName }
    })
  
    runSpec(app, jsdomContext, done, matcher, options)
  })
}

const runSpec = (app, context, done, matcher, options) => {
  const observations = []

  new ProgramRunner(app, context, options || { timeout: 500 })
    .on('observation', (observation) => {
      observations.push(observation)
    })
    .on('complete', () => {
      matcher(observations)
      done()
    })
    .on('error', (err) => {
      done(err)
    })
    .run()
}
