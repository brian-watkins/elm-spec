const {expect, test} = require('@oclif/test')
const sinon = require('sinon')
const rewire = require('rewire')
const cmd = rewire('..')

describe('elm-spec-runner', () => {
  context("when the specified elm executable does not exist", () => {
    test
    .do(() => cmd.run(["--elm", "blah"]))
    .catch(err => expect(err.message).to.contain("No elm executable found at: blah"))
    .it('gives an error message')
  })

  context("when the specs glob is not really a glob", () => {
    test
    .do(() => cmd.run(["--elm", "../../node_modules/.bin/elm", "--specs", "dsfsd/d///_"]))
    .catch(err => expect(err.message).to.contain("No spec modules found matching: dsfsd/d///_"))
    .it('gives an error message')
  })

  context("when the specs glob does not match any files", () => {
    test
    .do(() => cmd.run(["--elm", "../../node_modules/.bin/elm", "--specs", "./no-specs/**/*Spec.elm"]))
    .catch(err => expect(err.message).to.contain("No spec modules found matching: ./no-specs/**/*Spec.elm"))
    .it('gives an error message')
  })

  context("tags", () => {
    let suiteRunnerSpy

    beforeEach(() => {
      suiteRunnerSpy = sinon.fake((context, reporter, options) => {
        return { runAll: function() {} }
      })

      cmd.__set__("Compiler", function() {})
      cmd.__set__("JsdomContext", function() { return { loadElm: () => {} }})
      cmd.__set__("SuiteRunner", suiteRunnerSpy)
      cmd.__set__("ElmContext", function() {})
    })

    context("when one tag is specified", () => {
      test
      .do(() => cmd.run([
        "--elm", "../../node_modules/.bin/elm",
        "--specs", "../elm-spec-core/tests/sample/specs/**/*Spec.elm",
        "--tag", "fun"
      ]))
      .it('passes the tag to the suite runner', () => {
        const actualTags = suiteRunnerSpy.args[0][2].tags
        expect(actualTags).to.deep.equal(['fun'])
      })
    })

    context("when multiple tags are specified", () => {
      test
      .do(() => cmd.run([
        "--elm", "../../node_modules/.bin/elm",
        "--specs", "../elm-spec-core/tests/sample/specs/**/*Spec.elm",
        "--tag", "fun",
        "--tag", "awesome",
        "--tag", "super"
      ]))
      .it('passes the tags to the suite runner', () => {
        const actualTags = suiteRunnerSpy.args[0][2].tags
        expect(actualTags).to.deep.equal(['fun', 'awesome', 'super'])
      })
    })

    context("when no tags are specified", () => {
      test
      .do(() => cmd.run([
        "--elm", "../../node_modules/.bin/elm",
        "--specs", "../elm-spec-core/tests/sample/specs/**/*Spec.elm",
      ]))
      .it('passes an empty array to the suite runner', () => {
        const actualTags = suiteRunnerSpy.args[0][2].tags
        expect(actualTags).to.deep.equal([])
      })
    })
  })
})
