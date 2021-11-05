const chai = require('chai')
const expect = chai.expect
const { expectSpec, expectAccepted, reportLine, expectRejected } = require("./helpers/SpecHelpers")

describe.only("validate http requests", () => {
  it("validates requests and responses for OpenApi v2", (done) => {
    expectSpec("HttpValidationSpec", "validateOpenApi_v2", done, (observations) => {
      openApiScenarios(observations)
    })
  })
  it("validates requests and responses for OpenApi v3", (done) => {
    expectSpec("HttpValidationSpec", "validateOpenApi_v3", done, (observations) => {
      openApiScenarios(observations)
    })
  })
})

const openApiScenarios = (observations) => {
  expectAccepted(observations[0])
  expectAccepted(observations[1])
  expectRejected(observations[2], [
    reportLine("An invalid request was made", "GET http://fake-api.com/my/messages/bad"),
    reportLine("The request did not match the path", "/my/messages/{messageId}"),
    reportLine("because", "messageId must be number")
  ])
  expectRejected(observations[3], [
    reportLine("An invalid request was made", "GET http://fake-api.com/my/messages/27"),
    reportLine("The request did not have the required header", "x-fun-times must be integer"),
  ])
}