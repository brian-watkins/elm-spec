import { onFinish } from "tape"
import test from "tape"
import { onObservation, onLog, prepareHarness } from "../../src"

export async function observe(t, scenario, name, expected, message) {
  await scenario.observe(name, expected, message)
}

export async function expectError(t, promiseGenerator, handler) {
  return new Promise(resolve => {
    promiseGenerator()
      .then(() => t.fail("should not resolve!"))
      .catch((message) => {
        handler(message)
      })
      .finally(resolve)
  })
}

export async function captureObservations(generator) {
  let observations = []
  onObservation((observation) => {
    observations.push(observation)
  })

  await generator()

  return observations
}

export async function captureLogs(generator) {
  let logs = []

  onLog((report) => {
    logs.push(report)
  })

  await generator()

  return logs
}

export function harnessTestGenerator(harnessModule) {
  const harnessTest = (name, testHandler) => {
    test(name, generateTestHandler(harnessModule, testHandler))
  }

  harnessTest.only = (name, testHandler) => {
    test.only(name, generateTestHandler(harnessModule, testHandler))
  }
  
  return harnessTest
}

function generateTestHandler(harnessModule, testHandler) {
  return async function (t) {
    setupDefaultHandlers(t)

    const harness = prepareHarness(harnessModule)
    t.teardown(() => {
      harness.stopScenario()
    })
    await testHandler(harness, t)
  }
}

function setupDefaultHandlers(t) {
  onObservation((observation, message) => {
    if (observation.summary === "ACCEPTED") {
      t.pass(message)
    }
  })

  onLog(() => {})
}

onFinish(() => {
  console.log("END")
})
