const {expect, test} = require('@oclif/test')
const cmd = require('..')

describe('elm-spec-runner', () => {
  context("when the gloabl elm executable does not exist", () => {
    test
    .env({PATH: "./nowhere"})
    .do(() => cmd.run([]))
    .catch(err => expect(err.message).to.contain("No elm executable found in the current path"))
    .it('gives an error message')
  })
  
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
})
