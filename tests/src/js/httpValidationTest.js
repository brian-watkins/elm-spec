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
    reportLine("An invalid request was made", "GET http://fake-api.com/my/messages/bad?someValue=12"),
    reportLine("Problem with path parameter", "messageId must be number")
  ])
  expectRejected(observations[3], [
    reportLine("An invalid request was made", "GET http://fake-api.com/my/messages/27?someValue=12"),
    reportLine("Problem with headers", "x-fun-times must be integer"),
  ])
  expectRejected(observations[4], [
    reportLine("An invalid request was made", "GET http://fake-api.com/my/messages/27?someValue=39"),
    reportLine("Problem with query", "someValue must be <= 20"),
  ])
  expectRejected(observations[5], [
    reportLine("An invalid request was made", "GET http://fake-api.com/my/messages/27?someValue=6"),
    reportLine("Problem with headers", "must have required property 'x-fun-times'"),
    reportLine("Problem with query", "someValue must be >= 10"),
  ])
  expectRejected(observations[6], [
    reportLine("An invalid response was returned for", "GET http://fake-api.com/my/messages/27?someValue=12"),
    reportLine("Problem with body", "response must have required property 'message'"),
    reportLine("Problem with body", "id must be integer"),
  ])
  expectAccepted(observations[7])
  expectAccepted(observations[8])
  expectRejected(observations[9], [
    reportLine("An invalid request was made", "POST http://fake-api.com/my/messages"),
    reportLine("Problem with body", "must have required property 'message'")
  ])
}