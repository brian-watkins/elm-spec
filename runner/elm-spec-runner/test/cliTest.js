const {expect, test} = require('@oclif/test')
const cmd = require('..')
const path = require('path')

describe('elm-spec-runner', () => {
  context("when the spec passes", () => {
    test
    .stdout()
    .do(async () => await cmd.run([
      "--elm", "../../node_modules/.bin/elm",
      "--cwd", "../elm-spec-core/tests/sample/",
      "--specs", "./specs/Passing/**/*Spec.elm",
    ]))
    .it('runs all the scenarios', (output) => {
      expect(output.stdout).to.contain("Accepted: 8")
    })
  })

  context("when tags are used", () => {
    test
    .stdout()
    .do(async () => await cmd.run([
      "--elm", "../../node_modules/.bin/elm",
      "--cwd", "../elm-spec-core/tests/sample/",
      "--specs", "./specs/Passing/**/*Spec.elm",
      "--tag", "tagged",
      "--tag", "fun"
    ]))
    .it('runs only the tagged scenarios', (output) => {
      expect(output.stdout).to.contain("Accepted: 4")
    })
  })

  context("when the spec fails", () => {
    test
    .stdout()
    .do(async () => await cmd.run([
      "--elm", "../../node_modules/.bin/elm",
      "--cwd", "../elm-spec-core/tests/sample/",
      "--specs", "./specs/WithFailure/MoreSpec.elm",
    ]))
    .it('includes the path to the spec with the failing scenario', (output) => {
      const fullPath = path.resolve("../elm-spec-core/tests/sample/specs/WithFailure/MoreSpec.elm")
      expect(output.stdout).to.contain(fullPath)
    })
  })

  context("when the specified elm executable does not exist", () => {
    test
    .do(async () => await cmd.run([
      "--elm", "blah"
    ]))
    .catch(err => expect(err.message).to.contain("No elm executable found at: blah"))
    .it('gives an error message')
  })

  context("when the specs glob is not really a glob", () => {
    test
    .do(async () => await cmd.run([
      "--elm", "../../node_modules/.bin/elm",
      "--specs", "dsfsd/d///_"
    ]))
    .catch(err => expect(err.message).to.contain("No spec modules found matching: dsfsd/d///_"))
    .it('gives an error message')
  })

  context("when the specs glob does not match any files", () => {
    test
    .do(async () => await cmd.run([
      "--elm", "../../node_modules/.bin/elm",
      "--specs", "./no-specs/**/*Spec.elm"
    ]))
    .catch(err => expect(err.message).to.contain("No spec modules found matching: ./no-specs/**/*Spec.elm"))
    .it('gives an error message')
  })
})
