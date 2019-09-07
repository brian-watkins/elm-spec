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
})
