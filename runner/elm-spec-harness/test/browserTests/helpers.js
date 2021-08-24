import { onFinish } from "tape"
import test from "tape"
import { startHarness, onObservation, onLog } from "../../src/HarnessRunner"

export async function observe(t, scenario, name, expected, message) {
  await scenario.observe(name, expected, message)
}

export async function expectRejection(t, promiseGenerator, handler) {
  return new Promise(resolve => {
    promiseGenerator()
      .then(() => t.fail("should not resolve!"))
      .catch((message) => {
        handler(message)
      })
      .finally(resolve)
  })
}

let rejectedObservations = []
let logs = []

export function harnessTestGenerator(harnessModule) {
  const harnessTest = (name, testHandler) => {
    test(name, async function (t) {

      onObservation((observation, message) => {
        if (observation.summary === "ACCEPTED") {
          t.pass(message)
        } else {
          rejectedObservations.push(observation)
        }
      })

      rejectedObservations = []
      logs = []
      const harness = startHarness(harnessModule)
      t.teardown(() => {
        harness.stop()
      })
      await testHandler(harness, t)
    })
  }

  harnessTest.only = (name, testHandler) => {
    test.only(name, async function (t) {
      onObservation((observation, message) => {
        if (observation.summary === "ACCEPTED") {
          t.pass(message)
        } else {
          rejectedObservations.push(observation)
        }
      })

      rejectedObservations = []
      logs = []
      const harness = startHarness(harnessModule)
      t.teardown(() => {
        harness.stop()
      })
      await testHandler(harness, t)
    })
  }
  
  return harnessTest
}

onLog((report) => {
  logs.push(report)
})

onFinish(() => {
  console.log("END")
})

export function getRejectedObservations() {
  return rejectedObservations
}

export function getLogs() {
  return logs
}