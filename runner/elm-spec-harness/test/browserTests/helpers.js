import { onFinish } from "tape"
import test from "tape"
import { startHarness } from "../../src/HarnessRunner"

export async function observe(t, harness, name, actual, message) {
  const observer = await harness.observe(name, actual)
  if (observer.summary === "ACCEPTED") {
    t.pass(message)
  } else {
    console.log("report", observer.report)
    t.fail(message)
  }
}


export function harnessTestGenerator(harnessModule) {
  const harnessTest = (name, testHandler) => {
    test(name, async function (t) {
      const harness = startHarness(harnessModule)
      t.teardown(() => {
        harness.stop()
      })
      await testHandler(harness, t)
    })
  }

  harnessTest.only = (name, testHandler) => {
    test.only(name, async function (t) {
      const harness = startHarness(harnessModule)
      t.teardown(() => {
        harness.stop()
      })
      await testHandler(harness, t)
    })
  }
  
  return harnessTest
}


onFinish(() => {
  console.log("END")
})
