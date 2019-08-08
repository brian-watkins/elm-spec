const chai = require('chai')
const expect = chai.expect
const specRunner = require('../../runner/src/core')

exports.expectFailingSpec = (specProgram, specName, done, matcher) => {
  runSpec(specProgram, specName, done, (observations) => {
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
  runSpec(specProgram, specName, done, (observations) => {
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
  runSpec(specProgram, specName, done, matcher)
}

const runSpec = (specProgram, specName, done, matcher) => {
  specRunner.run(specProgram, specName)
    .then((observations) => {
      matcher(observations)
      done()
    })
    .catch((err) => {
      done(err)
    })
}