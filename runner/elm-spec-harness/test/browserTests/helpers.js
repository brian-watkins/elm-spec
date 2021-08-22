import { onFinish } from "tape"
import test from "tape"
import { startHarness, onObservation } from "../../src/HarnessRunner"

export async function observe(t, scenario, name, expected, message) {
  await scenario.observe(name, expected, { t, message })
}

let rejectedObservations = []

export function harnessTestGenerator(harnessModule) {
  const harnessTest = (name, testHandler) => {
    test(name, async function (t) {
      rejectedObservations = []
      const harness = startHarness(harnessModule)
      t.teardown(() => {
        harness.stop()
      })
      await testHandler(harness, t)
    })
  }

  harnessTest.only = (name, testHandler) => {
    test.only(name, async function (t) {
      rejectedObservations = []
      const harness = startHarness(harnessModule)
      t.teardown(() => {
        harness.stop()
      })
      await testHandler(harness, t)
    })
  }
  
  return harnessTest
}

onObservation((observation, data) => {
  if (observation.summary === "ACCEPTED") {
    data.t.pass(data.message)
  } else {
    rejectedObservations.push(observation)
  }
})

onFinish(() => {
  console.log("END")
})

export function getRejectedObservations() {
  return rejectedObservations
}