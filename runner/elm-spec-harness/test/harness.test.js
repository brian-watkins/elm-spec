import test from "tape";
import { runTests, expectPassingTest } from "./runTests"

runTests((testOutput) => {

  test('basics', function (t) {
    expectPassingTest(t, testOutput, "it finds the default attributes", "a test passes that observes the default model")
    expectPassingTest(t, testOutput, "it finds the configured default name", "a test passes that configures the setup")
    expectPassingTest(t, testOutput, "it counts the number of clicks", "a test passes that runs steps and changes the model")
    expectPassingTest(t, testOutput, "it counts the number of clicks again", "a test passes that runs steps and changes the model again after an observation")
    expectPassingTest(t, testOutput, "it resets the app at the beginning of each test", "a test passes that depends on the app model being reset")
    expectPassingTest(t, testOutput, "it finds the updated name", "a test passes that involves sending a message to the app")
    expectPassingTest(t, testOutput, "it observes that the request triggered by the port message was processed", "a test passes where a port message triggers a command")
    expectPassingTest(t, testOutput, "it runs the initial command", "a test passes that runs an initial command")
    expectPassingTest(t, testOutput, "it receives the initial port command", "a test passes that sends an initial port command")
    expectPassingTest(t, testOutput, "it finds the name updated after the message is received", "a test passes that sends a message to the app in response to receiving one")
    expectPassingTest(t, testOutput, "it observes that the stubbed response was processed", "a test passes that requires the context to be configured")
    t.end()
  })

  test('navigation', function (t) {
    expectPassingTest(t, testOutput, "it observes that the initial location was processed", "a test passes that sets an initial location")
    expectPassingTest(t, testOutput, "the updated location was processed", "a test passes that changes the location")
    expectPassingTest(t, testOutput, "the location change request was processed", "a test passes that depends on a url request")
    expectPassingTest(t, testOutput, "the app shows it has navigated to an external page", "a test passes that navigates to an external url")
    expectPassingTest(t, testOutput, "the external location is recorded", "a test passes that observes the location")
    expectPassingTest(t, testOutput, "the app shows it has navigated to the external page specified by the port", "a test passes that changes the location from a port")
    expectPassingTest(t, testOutput, "it rejects the url request runSteps promise with an error", "a test fails if a url request is made without setting navigation config")
    expectPassingTest(t, testOutput, "it rejects the url change runSteps promise with an error", "a test fails if a url change occurs without setting navigation config")
    t.end()
  })

  test('animation', function (t) {
    expectPassingTest(t, testOutput, "it finds one element after an animation frame", "a test passes that subscribes to animation frames")
    expectPassingTest(t, testOutput, "it finds one element after an animation frame on the next setup", "lingering animation frames are reset between setups")
    t.end()
  })

  test('handlers', function (t) {
    expectPassingTest(t, testOutput, "it handles the rejected observation", "observations are handled")
    expectPassingTest(t, testOutput, "it handles the expected log", "logs are handled")
    t.end()
  })

  test("failures", function (t) {
    expectPassingTest(t, testOutput, "it throws an exception when the module does not exist", "prepareHarness throws an Error if the module does not exist")
    expectPassingTest(t, testOutput, "it rejects the start promise with an error when the versions are out of sync", "harness.start rejects if the elm-spec core version is wrong")
    expectPassingTest(t, testOutput, "it rejects the start promise with an error", "harness.start rejects if the setup does not exist")
    expectPassingTest(t, testOutput, "it rejects the start config json with an error", "harness.start rejects if the config cannot be decoded")
    expectPassingTest(t, testOutput, "it rejects the runSteps promise with an error", "scenario.runSteps rejects if the steps do not exist")
    expectPassingTest(t, testOutput, "it rejects the steps config json with an error", "scenario.runSteps rejects if the config cannot be decoded")
    expectPassingTest(t, testOutput, "it rejects the observe promise with an error", "scenario.oberve rejects if the expectation does not exist")
    expectPassingTest(t, testOutput, "it rejects the observe config json with an error", "scenario.observe rejects if the config cannot be decoded")
    expectPassingTest(t, testOutput, "it explains that the step failed", "scenario.runSteps emits a rejected expectation if a step aborts")
    expectPassingTest(t, testOutput, "it emits an observation that the step request failed", "scenario.runSteps emits a rejected expectation if a step request aborts")
    expectPassingTest(t, testOutput, "it explains that the observer failed", "scenario.observe emits a rejected expectation if an observer inquiry aborts")
    t.end()
  })

})