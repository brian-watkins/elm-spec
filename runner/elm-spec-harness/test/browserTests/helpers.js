import { onFinish } from "tape"
import * as runner from "../../src/HarnessRunner"
import test from "tape"
import * as harness from "../../src/HarnessRunner"

export async function observe(t, name, actual, message) {
  const observer = await runner.observe(name, actual)
  if (observer.summary === "ACCEPTED") {
    t.pass(message)
  } else {
    console.log("report", observer.report)
    t.fail(message)
  }
}

export async function harnessTest(name, testHandler) {
  test(name, async function(t) {
    t.teardown(() => {
      harness.stop()
    })
    await testHandler(t)
  })
}

harnessTest.only = (name, testHandler) => {
  test.only(name, async function(t) {
    t.teardown(() => {
      harness.stop()
    })
    await testHandler(t)
  })
}

onFinish(() => {
  console.log("END")
})
