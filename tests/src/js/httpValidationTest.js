const { expect } = require("chai")
const { expectSpec, expectAccepted, reportLine, expectRejected } = require("./helpers/SpecHelpers")

describe("validate http requests", () => {
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
  it("reports on errors with the open api spec file", (done) => {
    expectSpec("HttpValidationSpec", "openApiErrors", done, (observations) => {
      expect(observations[0].summary).to.equal("REJECTED")
      expect(observations[0].description).to.equal("Unable to configure scenario")
      expect(observations[0].conditions).to.deep.equal([
        "Errors with the OpenApi spec file",
        "Scenario: Bad path to OpenApi spec file",
      ])
      expect(observations[0].report[0].statement).to.equal("OpenApi document not found at")
      expect(observations[0].report[0].detail).to.contain("fixtures/aFileThatDoesNotExist.yaml")

      expect(observations[1].report[0].statement).to.equal("Unable to parse OpenApi document at")
      expect(observations[1].report[0].detail).to.contain("fixtures/specWithBadYaml.yaml")
      expect(observations[1].report[1].statement).to.equal("YAML is invalid")
      expect(observations[1].report[1].detail).to.not.be.null
    })
  })
  // Note: Need to make sure we cover the case where file loading capability is not available!
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
  expectRejected(observations[10], [
    reportLine("An invalid response was returned for", "POST http://fake-api.com/my/messages"),
    reportLine("Problem with headers", "location must NOT have fewer than 5 characters"),
    reportLine("Problem with headers", "x-fun-times must be integer")
  ])
  expectRejected(observations[11], [
    reportLine("An invalid response was returned for", "POST http://fake-api.com/my/messages"),
    reportLine("An unknown status code was used and no default was provided.")
  ])
  expectRejected(observations[12], [
    reportLine("An invalid request was made", "GET http://fake-api.com/some/unknown/path"),
    reportLine("The OpenAPI document contains no path that matches this request.")
  ])
  expectRejected(observations[13], [
    reportLine("An invalid request was made", "PATCH http://fake-api.com/my/messages/18"),
    reportLine("The OpenAPI document contains no matching operation for this request.")
  ])
}

