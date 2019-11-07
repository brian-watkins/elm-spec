const chai = require('chai')
const expect = chai.expect
const SpecRunner = require('../../runner/elm-spec-core/src/programRunner')
const SpecCompiler = require('../../runner/elm-spec-runner/src/spec/compiler')
const GlobalContext = require('../../runner/elm-spec-runner/src/spec/globalContext')
const JsdomContext = require('../../runner/elm-spec-runner/src/spec/jsdomContext')
const HtmlPlugin = require('../../runner/elm-spec-core/src/plugin/htmlPlugin')
const HttpPlugin = require('../../runner/elm-spec-core/src/plugin/httpPlugin')

exports.expectFailingBrowserSpec = (specProgram, specName, done, matcher) => {
  expectFailure(runBrowserTestSpec, specProgram, specName, done, matcher)
}

exports.expectFailingSpec = (specProgram, specName, done, matcher) => {
  expectFailure(runTestSpec, specProgram, specName, done, matcher)
}

const expectFailure = (runner, specProgram, specName, done, matcher) => {
  runner(specProgram, specName, done, (observations) => {
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

exports.expectPassingBrowserSpec = (specProgram, specName, done, matcher) => {
  expectPass(runBrowserTestSpec, specProgram, specName, done, matcher)
}

exports.expectPassingSpec = (specProgram, specName, done, matcher) => {
  expectPass(runTestSpec, specProgram, specName, done, matcher)
}

const expectPass = (runner, specProgram, specName, done, matcher) => {
  runner(specProgram, specName, done, (observations) => {
    const rejections = observations.filter((o) => o.summary === "REJECT")
    if (rejections.length > 0) {
      const errors = rejections
        .map(o => o.report)
        .map((r) => r.map(o => o.statement + " " + o.detail).join(" "))
        .join("\n\n")
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

exports.expectSpec = (specProgram, specName, done, matcher, options) => {
  runTestSpec(specProgram, specName, done, matcher, options)
}

exports.expectBrowserSpec = (specProgram, specName, done, matcher, options) => {
  runBrowserTestSpec(specProgram, specName, done, matcher, options)
}

const compiler = new SpecCompiler({
  specPath: "./src/Specs/*Spec.elm",
  elmPath: "../node_modules/.bin/elm"
})

const testCompiler = {
  compile: () => {
    if (!this.compiledCode) {
      return compiler.compile()
        .then((code) => {
          this.compiledCode = code
          return code
        })
    } else {
      return Promise.resolve(this.compiledCode)
    }
  }
}

exports.globalContext = new GlobalContext(testCompiler)

exports.htmlContext = htmlContext = new JsdomContext(testCompiler)

const runTestSpec = (specProgram, specName, done, matcher, options) => {
  this.globalContext.evaluate((Elm) => {
    var app = Elm.Specs[specProgram].init({
      flags: { specName }
    })

    this.runSpec(app, this.globalContext, {}, done, matcher, options)
  })
}

const runBrowserTestSpec = (specProgram, specName, done, matcher, options) => {
  this.htmlContext.evaluate((Elm, appElement, clock, window) => {
    const plugins = {
      "_html": new HtmlPlugin(this.htmlContext, window, clock),
      "_http": new HttpPlugin(window)
    }

    var app = Elm.Specs[specProgram].init({
      node: appElement,
      flags: { specName }
    })
  
    this.htmlContext.dom.window._elm_spec.app = app

    this.runSpec(app, this.htmlContext, plugins, done, matcher, options)
  })
}

exports.runSpec = (app, context, plugins, done, matcher, options) => {
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