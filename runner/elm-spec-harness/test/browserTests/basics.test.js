import test from "tape"
import * as harness from "../../src/HarnessRunner"
import { observe } from "./helpers"

test("initial state of app", async function (t) {
  await harness.setup("withName", { name: "Professor Strange" })
  await observe(t, "name", "Professor Strange", "it finds the configured default name")
  await observe(t, "attributes", [ "cool", "fun" ], "it finds the default attributes")
})

test("the view updates", async function(t) {
  await harness.setup("default")
  await harness.runSteps("click", 5)
  await observe(t, "count", "5 clicks!", "it counts the number of clicks")
  await harness.runSteps("click", 2)
  await observe(t, "count", "7 clicks!", "it counts the number of clicks again")
})

test("the app is reset", async function(t) {
  await harness.setup("default")
  await observe(t, "count", "0 clicks!", "it resets the app at the beginning of each test")
})

test("a message is sent to the app", async function(t) {
  await harness.setup("default")
  harness.getElmApp().ports.triggerStuff.send({ name: "Super cool dude" })
  await observe(t, "name", "Super cool dude", "it finds the updated name")
})

test("the iniial command sends a message out of the app", async function(t) {
  await harness.setup("withInitialCommand", [ "apple", "banana", "pear" ])
  await observe(t, "stuff", "Got apple, banana, pear (3)", "it runs the initial command")
})

test("a message is sent in response to a message that is received", async function(t) {
  await harness.setup("default")
  harness.getElmApp().ports.inform.subscribe(data => {
    harness.getElmApp().ports.triggerStuff.send({ name: "Dr. Cool" })
  })
  await harness.runSteps("inform")
  await observe(t, "name", "Dr. Cool", "it finds the name updated after the message is received")
})

test("the setup configures the context to stub an HTTP request", async function(t) {
  await harness.setup("withStub", { thing: "trees", count: 17 })
  await harness.runSteps("requestStuff")
  await observe(t, "stuff", "Got trees (17)", "it observes that the stubbed response was processed")
})
