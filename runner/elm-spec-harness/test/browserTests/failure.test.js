import { startHarness, onObservation } from "../../src/HarnessRunner"
import test from "tape"
import { expectRejection, getRejectedObservations, harnessTestGenerator } from "./helpers"

test("harness module does not exist", function(t) {
  t.throws(() => { startHarness("No.Module.That.Exists") }, /Module No.Module.That.Exists does not exist!/, "it throws an exception when the module does not exist")
  t.end()
})

const harnessTest = harnessTestGenerator("Basic.Harness")

harnessTest("setup doesn't exist", async function(harness, t) {
  await expectRejection(t, () => harness.start("some-setup-that-does-not-exist"), (message) => {
    t.equals(message, "No setup has been exposed with the name some-setup-that-does-not-exist", "it rejects the start promise with an error")
  })
})

harnessTest("steps don't exist", async function(harness, t) {
  const scenario = await harness.start("default")
  await expectRejection(t, () => scenario.runSteps("some-steps-that-do-not-exist"), (message) => {
    t.equals(message, "No steps have been exposed with the name some-steps-that-do-not-exist", "it rejects the runSteps promise with an error")
  })
})

harnessTest("expectation doesn't exist", async function(harness, t) {
  const scenario = await harness.start("default")
  await expectRejection(t, () => scenario.observe("some-expectation-that-does-not-exist"), (message) => {
    t.equals(message, "No expectation has been exposed with the name some-expectation-that-does-not-exist", "it rejects the observe promise with an error")
  })
})

harnessTest("a step aborts", async function(harness, t) {
  let observations = []
  onObservation((observation) => {
    observations.push(observation)
  })

  const scenario = await harness.start("default")
  await scenario.runSteps("badSteps")

  t.equal(observations.length, 1, "it emits a rejected expectation")
  t.equal(observations[0].report[0].statement, "No match for selector", "it explains that the step failed")
})