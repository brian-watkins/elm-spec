const { expectRejected, reportLine } = require("./SpecHelpers")

exports.expectRejectedWhenNoElementTargeted = (eventName, observation) => {
  expectRejected(observation, [
    reportLine("No element targeted for event", eventName)
  ])
}

exports.expectRejectedWhenDocumentTargeted = (eventName, observation) => {
  expectRejected(observation, [
    reportLine("Event not supported when document is targeted", eventName)
  ])
}

exports.expectRejectedOnViewReRender = (observation) => {
  expectRejected(observation, [
    reportLine("No match for selector", "#conditional")
  ])
}