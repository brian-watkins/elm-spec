const chai = require('chai')
const expect = chai.expect
const SpecRunner = require('../../runner/elm-spec-core/src/programRunner')
const SpecCompiler = require('elm-spec-core/src/compiler')
const JsdomContext = require('../../runner/elm-spec-runner/src/jsdomContext')
const HtmlPlugin = require('../../runner/elm-spec-core/src/plugin/htmlPlugin')
const HttpPlugin = require('../../runner/elm-spec-core/src/plugin/httpPlugin')


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

const jsdomContext = new JsdomContext(testCompiler)

const runProgramInJsdom = (specProgram, done, matcher) => {
  jsdomContext.evaluate((Elm) => {
    jsdomContext.evaluateProgram(Elm.Specs[specProgram], (app, plugins) => {
      runSpec(app, jsdomContext, plugins, done, matcher)
    })  
  })  
}

const runProgramInBrowser = (specProgram, done, matcher) => {
  page.evaluate((program) => {
    return _elm_spec.runProgram(program)
  }, specProgram).then((observations) => {
    matcher(observations)
    done()
  }).catch((err) => {
    done(err)
  })
}

const runSpecInBrowser = (specProgram, specName, done, matcher, options) => {  
  page.evaluate((program, name, options) => { 
    return _elm_spec.runSpec(program, name, options)
  }, specProgram, specName, options).then((observations) => {
    matcher(observations)
    done()
  }).catch((err) => {
    done(err)
  })
}

const runSpecInJsdom = (specProgram, specName, done, matcher, options) => {
  jsdomContext.evaluate((Elm, window) => {
    const plugins = {
      "_html": new HtmlPlugin(jsdomContext, window),
      "_http": new HttpPlugin(window)
    }

    var app = Elm.Specs[specProgram].init({
      flags: { specName }
    })
  
    runSpec(app, jsdomContext, plugins, done, matcher, options)
  })
}

const runSpec = (app, context, plugins, done, matcher, options) => {
  const observations = []

  new SpecRunner(app, context, plugins, options || { timeout: 500 })
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
