const chai = require('chai')
const expect = chai.expect
const SpecRunner = require('../../runner/src/core/runner')
const SpecCompiler = require('../../runner/src/node-runner/compiler')
const GlobalContext = require('../../runner/src/node-runner/globalContext')
const HtmlContext = require('../../runner/src/node-runner/htmlContext')
const HtmlPlugin = require('../../runner/src/core/htmlPlugin')

exports.expectFailingSpec = (specProgram, specName, done, matcher) => {
  runTestSpec(specProgram, specName, done, (observations) => {
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
  runTestSpec(specProgram, specName, done, (observations) => {
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
  runTestSpec(specProgram, specName, done, matcher)
}

const compiler = new SpecCompiler({
  specPath: "./src/Specs/*Spec.elm",
  elmPath: "../node_modules/.bin/elm",
  outputPath: "./compiled-specs.js"
})

exports.globalContext = new GlobalContext(compiler)

exports.htmlContext = htmlContext = new HtmlContext(compiler)

const runTestSpec = (specProgram, specName, done, matcher) => {
  this.globalContext.evaluate((Elm) => {
    var app = Elm.Specs[specProgram].init({
      flags: { specName }
    })

    this.runSpec(app, {}, done, matcher)
  })
}

exports.runBrowserTestSpec = (specProgram, specName, done, matcher) => {
  this.htmlContext.evaluate((Elm, appElement, document) => {
    const plugins = {
      "_html": new HtmlPlugin(document)
    }

    var app = Elm.Specs[specProgram].init({
      node: appElement,
      flags: { specName }
    })
  
    this.runSpec(app, plugins, done, matcher)
  })
}

exports.runSpec = (app, plugins, done, matcher) => {
  const observations = []

  new SpecRunner(app, plugins)
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

  app.ports.sendIn.send({ home: "_spec", name: "state", body: "START" })
}