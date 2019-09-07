const chai = require('chai')
const expect = chai.expect
const SpecRunner = require('../../runner/elm-spec-core/src/programRunner')
const SpecCompiler = require('../../runner/elm-spec-runner/src/spec/compiler')
const GlobalContext = require('../../runner/elm-spec-runner/src/spec/globalContext')
const HtmlContext = require('../../runner/elm-spec-runner/src/spec/htmlContext')
const HtmlPlugin = require('../../runner/elm-spec-core/src/htmlPlugin')

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

exports.expectSpec = (specProgram, specName, done, matcher) => {
  runTestSpec(specProgram, specName, done, matcher)
}

exports.expectBrowserSpec = (specProgram, specName, done, matcher) => {
  runBrowserTestSpec(specProgram, specName, done, matcher)
}

const compiler = new SpecCompiler({
  specPath: "./src/Specs/*Spec.elm",
  elmPath: "../node_modules/.bin/elm"
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

const runBrowserTestSpec = (specProgram, specName, done, matcher) => {
  this.htmlContext.evaluate((Elm, appElement, clock, window) => {
    const plugins = {
      "_html": new HtmlPlugin(window, clock)
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
}