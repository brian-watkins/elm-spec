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

test("a message is sent to the app", async function(t) {
  await runner.setup()
  runner.getElmApp().ports.triggerStuff.send({ name: "Super cool dude" })
  await expectEqual(t, "name", "Super cool dude", "it finds the updated name")
})

test("a message is received from the app", async function(t) {
  await runner.setup()
  runner.getElmApp().ports.inform.subscribe(data => {
    t.deepEquals(data, { attributes: [ "awesome", "cool", "fun" ] }, "it receives the expected message")
  })
  await runner.runSteps("inform")
})

test("a message is sent in response to a message that is received", async function(t) {
  await runner.setup()
  runner.getElmApp().ports.inform.subscribe(data => {
    runner.getElmApp().ports.triggerStuff.send({ name: "Dr. Cool" })
  })
  await runner.runSteps("inform")
  await expectEqual(t, "name", "Dr. Cool", "it finds the name updated after the message is received")
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