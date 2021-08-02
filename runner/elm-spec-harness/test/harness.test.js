import test from "tape";
import { runTests } from "./runTests"

runTests((testOutput) => {

  test('basics', function (t) {
    expectPassingTest(t, testOutput, "it finds the default attributes", "a test observing the default model passes")
    expectPassingTest(t, testOutput, "it finds the configured default name", "a test passes that configures the setup")
    expectPassingTest(t, testOutput, "it counts the number of clicks", "a test passes that runs steps and changes the model")
    expectPassingTest(t, testOutput, "it counts the number of clicks again", "a test passes that runs steps and changes the model again after an observation")
    expectPassingTest(t, testOutput, "it resets the app at the beginning of each test", "a test passes that depends on the app model being reset")
    expectPassingTest(t, testOutput, "it finds the updated name", "a test passes that involves sending a message to the app")
    expectPassingTest(t, testOutput, "it runs the initial command", "a test passes that runs an initial command")
    expectPassingTest(t, testOutput, "it finds the name updated after the message is received", "a test passes that sends a message to the app in response to receiving one")
    expectPassingTest(t, testOutput, "it observes that the stubbed response was processed", "a test passes that requires the context to be configured")
    t.end()
  })
  
  test('navigation', function(t) {
    expectPassingTest(t, testOutput, "it observes that the initial location was processed", "a test passes that sets an initial location")
    expectPassingTest(t, testOutput, "the updated location was processed", "a test passes that changes the location")
    expectPassingTest(t, testOutput, "the location change request was processed", "a test passes that depends on a url request")
    expectPassingTest(t, testOutput, "the app shows it has navigated to an external page", "a test passes that navigates to an external url")
    expectPassingTest(t, testOutput, "the external location is recorded", "a test passes that observes the location")
    expectPassingTest(t, testOutput, "the app shows it has navigated to the external page specified by the port", "a test passes that changes the location from a port")
    t.end()
  })

})

const expectPassingTest = (t, output, testName, message) => {
  expectListItemMatches(t, output, `^ok \\d+ ${testName}$`, message)
}

const expectListItemMatches = (t, list, regex, success) => {
  if (list.find(element => element.match(regex))) {
    t.pass(success)
  } else {
    t.fail(`Expected [ ${list} ] to have an item matching: ${regex}`)
  }
}