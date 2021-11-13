const { expect } = require("chai")
const { expectSpec, expectAccepted, reportLine, expectRejected } = require("./helpers/SpecHelpers")

describe("validate http requests", () => {
  it("validates requests and responses for OpenApi v2 in YAML", (done) => {
    expectSpec("HttpValidationSpec", "validateOpenApi_v2_yaml", done, (observations) => {
      openApiScenarios(observations)
    })
  })
  it("validates requests and responses for OpenApi v2 in JSON", (done) => {
    expectSpec("HttpValidationSpec", "validateOpenApi_v2_json", done, (observations) => {
      openApiScenarios(observations)
    })
  })
  it("validates requests and responses for OpenApi v3 in YAML", (done) => {
    expectSpec("HttpValidationSpec", "validateOpenApi_v3_yaml", done, (observations) => {
      openApiScenarios(observations)
    })
  })
  it("validates requests and responses for OpenApi v3 in JSON", (done) => {
    expectSpec("HttpValidationSpec", "validateOpenApi_v3_json", done, (observations) => {
      openApiScenarios(observations)
    })
  })
  it("validates requests and responses with multiple contracts", (done) => {
    expectSpec("HttpValidationSpec", "multipleContracts", done, (observations) => {
      expectAccepted(observations[0])
      expectAccepted(observations[1])
      expectAccepted(observations[2])
      expectAccepted(observations[3])
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
      expect(observations[0].report[0].statement).to.equal("Unable to read file at")
      expect(observations[0].report[0].detail).to.contain("fixtures/aFileThatDoesNotExist.yaml")

      expect(observations[1].report[0].statement).to.equal("Unable to parse OpenApi document at")
      expect(observations[1].report[0].detail).to.contain("fixtures/specWithBadYaml.yaml")
      expect(observations[1].report[1].statement).to.not.be.null

      expect(observations[2].report[0].statement).to.equal("Unable to parse OpenApi document at")
      expect(observations[2].report[0].detail).to.contain("fixtures/specWithBadJson.txt")
      expect(observations[2].report[1].statement).to.not.be.null

      expect(observations[3].report[0].statement).to.equal("Invalid OpenApi document")
      expect(observations[3].report[0].detail).to.contain("fixtures/badOpenApiSpec.yaml")
      expect(observations[3].report[1].statement).to.equal("must have required property 'info'")
      expect(observations[3].report[2].statement).to.equal("/paths must be object")

      expect(observations[4].report[0].statement).to.equal("Invalid OpenApi document")
      expect(observations[4].report[0].detail).to.contain("fixtures/unknownVersionOpenApiSpec.yaml")
      expect(observations[4].report[1].statement).to.equal("Unable to determine OpenApi version")
    })
  })
  it("registers contracts when stubs are reset during a spec", (done) => {
    expectSpec("HttpValidationSpec", "resetStubs", done, (observations) => {
      expectRejected(observations[0], [
        reportLine("An invalid request was made", "POST http://fake-api.com/my/messages\nHeaders: {\"content-type\":\"application/json\"}\nBody: {\"blerg\":17}"),
        reportLine("Problem with body", "must have required property 'message'")
      ])
    })
  })
})

const openApiScenarios = (observations) => {
  expectAccepted(observations[0])
  expectAccepted(observations[1])
  expectRejected(observations[2], [
    reportLine("An invalid request was made", "GET http://fake-api.com/my/messages/bad?someValue=12\nHeaders: {\"x-fun-times\":\"31\"}\nBody: <empty>"),
    reportLine("Problem with path parameter", "messageId must be number")
  ])
  expectRejected(observations[3], [
    reportLine("An invalid request was made", "GET http://fake-api.com/my/messages/27?someValue=12\nHeaders: {\"x-fun-times\":\"blah\"}\nBody: <empty>"),
    reportLine("Problem with headers", "x-fun-times must be integer"),
  ])
  expectRejected(observations[4], [
    reportLine("An invalid request was made", "GET http://fake-api.com/my/messages/27?someValue=39\nHeaders: {\"x-fun-times\":\"31\"}\nBody: <empty>"),
    reportLine("Problem with query", "someValue must be <= 20"),
  ])
  expectRejected(observations[5], [
    reportLine("An invalid request was made", "GET http://fake-api.com/my/messages/27?someValue=6\nHeaders: {\"x-cool-times\":\"blah\"}\nBody: <empty>"),
    reportLine("Problem with headers", "must have required property 'x-fun-times'"),
    reportLine("Problem with query", "someValue must be >= 10"),
  ])
  expectRejected(observations[6], [
    reportLine("An invalid response was returned for", "GET http://fake-api.com/my/messages/27?someValue=12"),
    reportLine("Response", "Status: 200\nHeaders: {}\nBody: {\"id\":\"should be a number\",\"blerg\":\"\"}"),
    reportLine("Problem with body", "must have required property 'message'"),
    reportLine("Problem with body", "id must be integer")
  ])
  expectAccepted(observations[7])
  expectAccepted(observations[8])
  expectRejected(observations[9], [
    reportLine("An invalid request was made", "POST http://fake-api.com/my/messages\nHeaders: {\"content-type\":\"application/json\"}\nBody: {\"blerg\":17}"),
    reportLine("Problem with body", "must have required property 'message'")
  ])
  expectRejected(observations[10], [
    reportLine("An invalid response was returned for", "POST http://fake-api.com/my/messages"),
    reportLine("Response", "Status: 201\nHeaders: {\"Location\":\"\",\"X-Fun-Times\":\"blerg\"}\nBody: <empty>"),
    reportLine("Problem with headers", "location must NOT have fewer than 5 characters"),
    reportLine("Problem with headers", "x-fun-times must be integer")
  ])
  expectRejected(observations[11], [
    reportLine("An invalid response was returned for", "POST http://fake-api.com/my/messages"),
    reportLine("Response", "Status: 500\nHeaders: {\"Location\":\"http://fake-api.com/my/messages/2\",\"X-Fun-Times\":\"27\"}\nBody: <empty>"),
    reportLine("An unknown status code was used and no default was provided.")
  ])
  expectRejected(observations[12], [
    reportLine("An invalid request was made", "GET http://fake-api.com/some/unknown/path"),
    reportLine("The OpenAPI document contains no path that matches this request.")
  ])
  expectRejected(observations[13], [
    reportLine("An invalid request was made", "PATCH http://fake-api.com/my/messages/18\nHeaders: {}\nBody: <empty>"),
    reportLine("The OpenAPI document contains no matching operation for this request.")
  ])
  expectAccepted(observations[14])
  expectAccepted(observations[15])
  expectRejected(observations[16], [
    reportLine("An invalid request was made", "POST http://fake-api.com/my/messages\nHeaders: {\"content-type\":\"application/json\"}\nBody: []"),
    reportLine("Problem with body", "must be object")
  ])
  expectRejected(observations[17], [
    reportLine("An invalid response was returned for", "GET http://fake-api.com/my/messages/27?someValue=12"),
    reportLine("Response", "Status: 200\nHeaders: {}\nBody: []"),
    reportLine("Problem with body", "must be object")
  ])
  expectRejected(observations[18], [
    reportLine("An invalid response was returned for", "GET http://fake-api.com/my/messages/27?someValue=12"),
    reportLine("Response", "Status: 200\nHeaders: {}\nBody: {\"id\":\"should be a number\",\"blerg\":\"\"}"),
    reportLine("Problem with body", "must have required property 'message'"),
    reportLine("Problem with body", "id must be integer")
  ])
}

