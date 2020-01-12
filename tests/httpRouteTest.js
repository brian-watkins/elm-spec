const {
  expectSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("Http Route", () => {
  context("queryParameter", () => {
    it("observes the query parameters as expected", (done) => {
      expectSpec("HttpRouteSpec", "queryParams", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff?*"),
          reportLine("List failed to match at position 1"),
          reportLine("Claim rejected for query parameter", "activity"),
          reportLine("List failed to match at position 1"),
          reportLine("Expected", "\"bowling\""),
          reportLine("to equal", "\"nothing\"")
        ])
        expectRejected(observations[2], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff?*"),
          reportLine("List failed to match at position 1"),
          reportLine("Claim rejected for query parameter", "unknown"),
          reportLine("List failed to match"),
          reportLine("Expected list to have length", "1"),
          reportLine("but it has length", "0")
        ])
        expectRejected(observations[3], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/stuff?activity=running"),
          reportLine("Expected list to have length", "1"),
          reportLine("but it has length", "0")
        ])
        expectAccepted(observations[4])
      })
    })
  })

  context("route query", () => {
    it("matches the route as expected", (done) => {
      expectSpec("HttpRouteSpec", "routeQuery", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
        expectAccepted(observations[4])
      })
    })
  })

  context("route origin", () => {
    it("matches the route as expected", (done) => {
      expectSpec("HttpRouteSpec", "routeOrigin", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectAccepted(observations[2])
        expectAccepted(observations[3])
        expectAccepted(observations[4])
        expectAccepted(observations[5])
        expectAccepted(observations[6])
        expectAccepted(observations[7])
        expectAccepted(observations[8])
        expectAccepted(observations[9])
        expectAccepted(observations[10])
        expectAccepted(observations[11])
        expectAccepted(observations[12])
        expectAccepted(observations[13])
        expectAccepted(observations[14])
        expectAccepted(observations[15])
        expectRejected(observations[16], [
          reportLine("Claim rejected for route", "GET */some/awesome/path"),
          reportLine("Expected list to have length", "1"),
          reportLine("but it has length", "0")
        ])
        expectAccepted(observations[17])
        expectAccepted(observations[18])
        expectAccepted(observations[19])
        expectAccepted(observations[20])
        expectAccepted(observations[21])
        expectAccepted(observations[22])
        expectAccepted(observations[23])
        expectAccepted(observations[24])
        expectAccepted(observations[25])
        expectAccepted(observations[26])
        expectAccepted(observations[27])
        expectAccepted(observations[28])
      })
    })
  })

  context("route path", () => {
    it("matches the route as expected", (done) => {
      expectSpec("HttpRouteSpec", "routePath", done, (observations) => {
        expectAccepted(observations[0])
        expectAccepted(observations[1])
        expectRejected(observations[2], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/awesome/stuff/:id/children"),
          reportLine("List failed to match at position 1"),
          reportLine("Claim rejected for path variable", "id"),
          reportLine("Expected", "\"21\""),
          reportLine("to equal", "\"nothing\"")
        ])
        expectRejected(observations[3], [
          reportLine("Claim rejected for route", "GET http://fake-api.com/awesome/stuff/:id/children"),
          reportLine("List failed to match at position 1"),
          reportLine("No path variable defined with the name", "something-else"),
          reportLine("Make sure to use Spec.Http.Route.withPath and Spec.Http.Route.Variable to define a path variable")
        ])
        expectAccepted(observations[4])
        expectAccepted(observations[5])
        expectAccepted(observations[6])
        expectAccepted(observations[7])
        expectAccepted(observations[8])
        expectAccepted(observations[9])
        expectAccepted(observations[10])
        expectAccepted(observations[11])
        expectAccepted(observations[12])
        expectAccepted(observations[13])
      })
    })
  })
})