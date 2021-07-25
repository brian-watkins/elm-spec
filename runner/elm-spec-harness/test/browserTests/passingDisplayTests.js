import test, { onFinish } from "tape"
import * as runner from "../../src/HarnessRunner"

test("initial state of app", async function (t) {
  await runner.setup()
  await expectEqual(t, "name", "Brian", "it finds the default name")
})

test("another test of the initial state", async function (t) {
  await runner.setup()
  await expectEqual(t, "attributes", [ "cool", "fun" ], "it finds the default attributes")
})

test("the view updates", async function(t) {
  await runner.setup()
  await runner.runSteps("click")
  await expectEqual(t, "count", "3 clicks!", "it counts the number of clicks")
})

test("the app is reset", async function(t) {
  await runner.setup()
  await expectEqual(t, "count", "0 clicks!", "it resets the app at the beginning of each test")
})



const expectEqual = async (t, name, actual, message) => {
  const observer = await runner.observe(name, actual)
  if (observer.summary === "ACCEPTED") {
    t.pass(message)
  } else {
    console.log("report", observer.report)
    t.fail(message)
  }
}

onFinish(() => {
  console.log("END")
})