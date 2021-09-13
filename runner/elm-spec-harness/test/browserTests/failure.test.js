import { prepareHarness } from "../../src"
import test from "fresh-tape"
import { expectError, captureObservations, harnessTestGenerator } from "./helpers"

test("harness module does not exist", function(t) {
  t.throws(() => { prepareHarness("No.Module.That.Exists") }, /Module No.Module.That.Exists does not exist!/, "it throws an exception when the module does not exist")
  t.end()
})

const harnessTest = harnessTestGenerator("Basic.Harness")

harnessTest("setup doesn't exist", async function(harness, t) {
  await expectError(t, () => harness.startScenario("some-setup-that-does-not-exist"), (error) => {
    t.equals(error.message, "No setup has been exposed with the name some-setup-that-does-not-exist", "it rejects the start promise with an error")
  })
})

harnessTest("setup configured with bad json", async function(harness, t) {
  await expectError(t, () => harness.startScenario("withName", 27), (error) => {
    t.true(error.message.startsWith("Unable to configure setup:"), "it rejects the start config json with an error")
  })
})

harnessTest("steps don't exist", async function(harness, t) {
  const scenario = await harness.startScenario("default")
  await expectError(t, () => scenario.runSteps("some-steps-that-do-not-exist"), (error) => {
    t.equals(error.message, "No steps have been exposed with the name some-steps-that-do-not-exist", "it rejects the runSteps promise with an error")
  })
})

harnessTest("steps configured with bad json", async function(harness, t) {
  const scenario = await harness.startScenario("default")
  await expectError(t, () => scenario.runSteps("click", "should-be-a-number"), (error) => {
    t.true(error.message.startsWith("Unable to configure steps:"), "it rejects the steps config json with an error")
  })
})


harnessTest("expectation doesn't exist", async function(harness, t) {
  const scenario = await harness.startScenario("default")
  await expectError(t, () => scenario.observe("some-expectation-that-does-not-exist"), (error) => {
    t.equals(error.message, "No expectation has been exposed with the name some-expectation-that-does-not-exist", "it rejects the observe promise with an error")
  })
})

harnessTest("expectation config cannot be decoded", async function(harness, t) {
  const scenario = await harness.startScenario("default")
  await expectError(t, () => scenario.observe("title", 32), (error) => {
    t.true(error.message.startsWith("Unable to configure expectation:"), "it rejects the observe config json with an error")
  })
})

harnessTest("a step aborts", async function(harness, t) {
  const observations = await captureObservations(async () => {
    const scenario = await harness.startScenario("default")
    await scenario.runSteps("badSteps")
  })

  t.equal(observations.length, 1, "it emits a rejected expectation")
  t.equal(observations[0].report[0].statement, "No match for selector", "it explains that the step failed")
})

harnessTest("an observer aborts", async function(harness, t) {
  const observations = await captureObservations(async () => {
    const scenario = await harness.startScenario("withStub", { thing: "apples", count: 4 })
    await scenario.runSteps("requestStuff")
    await scenario.observe("requestsMatching", { regex: "[2", count: 1 })
  })

  t.equal(observations[0].summary, "REJECTED", "it emits a rejected expectation")
  t.equal(observations[0].report[0].statement, "Unable to parse regular expression used to observe requests", "it explains that the observer failed")
})

const fileHarnessTest = harnessTestGenerator("File.Harness")

fileHarnessTest("a step request fails", async function(harness, t) {
  const observations = await captureObservations(async () => {
    const scenario = await harness.startScenario("default")
    await scenario.runSteps("selectFile", "some-non-existent-file.txt")
  })

  t.equal(observations.length, 1, "it emits an observation that the step request failed")
})