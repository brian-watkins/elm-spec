const chai = require('chai')
const expect = chai.expect
const SpecRunner = require('../../runner/elm-spec-core/src/programRunner')
const SpecCompiler = require('elm-spec-core/src/compiler')
const JsdomContext = require('../../runner/elm-spec-runner/src/jsdomContext')
const HtmlPlugin = require('../../runner/elm-spec-core/src/plugin/htmlPlugin')
const HttpPlugin = require('../../runner/elm-spec-core/src/plugin/httpPlugin')


exports.expectPassingSpec = (specProgram, specName, done, matcher) => {
  this.expectSpec(specProgram, specName, done, (observations) => {
    for (let i = 0; i < observations.length; i++) {
      this.expectAccepted(observations[i])
    }
    if (matcher) matcher(observations)
  })
}

exports.expectSpec = (specProgram, specName, done, matcher, options) => {
  runSpecInBrowser(specProgram, specName, done, matcher, options)
}

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

exports.htmlContext = htmlContext = new JsdomContext(testCompiler)

const runSpecInBrowser = (specProgram, specName, done, matcher, options) => {
  this.htmlContext.evaluate((Elm, window) => {
    const plugins = {
      "_html": new HtmlPlugin(this.htmlContext, window),
      "_http": new HttpPlugin(window)
    }

    var app = Elm.Specs[specProgram].init({
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