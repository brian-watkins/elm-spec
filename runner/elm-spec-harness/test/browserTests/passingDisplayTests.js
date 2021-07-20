import test, { onFinish } from "tape"
import * as runner from "../../src/HarnessRunner"

test("initial state of app", async function (t) {
  runner.setup()
  await expectEqual(t, "name", "Brian", "it finds the default name")
})

test("another test of the initial state", async function (t) {
  runner.setup()
  await expectEqual(t, "attributes", [ "cool", "fun" ], "it finds the default attributes")
})

test("the initial view", async function(t) {
  runner.setup()
  await expectEqual(t, "title", "Hey!", "it shows the page title in the view")
})

const expectEqual = async (t, name, actual, message) => {
  const observer = await runner.observe(name, actual)
  if (observer.summary === "ACCEPTED") {
    t.pass(message)
  } else {
    t.fail(message)
  }
}

onFinish(() => {
  console.log("END")
})