const {expect, test} = require('@oclif/test')
const cmd = require('..')

describe('elm-spec-runner', () => {
  context("when the specified elm executable does not exist", () => {
    test
    .do(async () => await cmd.run([
      "--elm", "blah"
    ]))
    .catch(err => expect(err.message).to.contain("No elm executable found at: blah"))
    .it('gives an error message')
  })

  context("when the elm.json cannot be found", () => {
    test
    .do(async () => await cmd.run([
      "--elm", "../../node_modules/.bin/elm",
      "--cwd", "../elm-spec-core/tests"
    ]))
    .catch(err => expect(err.message).to.contain("Expected an elm.json at: ../elm-spec-core/tests/elm.json"))
    .it('prints an error message')
  })

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

})