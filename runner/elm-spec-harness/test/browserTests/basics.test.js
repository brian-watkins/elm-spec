import { harnessTestGenerator, observe } from "./helpers"

const harnessTest = harnessTestGenerator("Basic.Harness")

harnessTest("initial state of app", async function (harness, t) {
  await harness.start("withName", { name: "Professor Strange" })
  await observe(t, harness, "name", "Professor Strange", "it finds the configured default name")
  await observe(t, harness, "attributes", [ "cool", "fun" ], "it finds the default attributes")
})

harnessTest("the view updates", async function(harness, t) {
  await harness.start("default")
  await harness.runSteps("click", 5)
  await observe(t, harness, "count", "5 clicks!", "it counts the number of clicks")
  await harness.runSteps("click", 2)
  await observe(t, harness, "count", "7 clicks!", "it counts the number of clicks again")
})

harnessTest("the app is reset", async function(harness, t) {
  await harness.start("default")
  await observe(t, harness, "count", "0 clicks!", "it resets the app at the beginning of each test")
})

harnessTest("a message is sent to the app that updates the model and runs a command", async function(harness, t) {
  await harness.start("default")
  harness.getElmApp().ports.triggerStuff.send({ name: "Super cool dude" })
  await harness.wait()
  await observe(t, harness, "name", "Super cool dude", "it finds the updated name")
  await observe(t, harness, "stuff", "Got apples (91)", "it observes that the request triggered by the port message was processed")
})

harnessTest("the iniial command sends an HTTP request", async function(harness, t) {
  await harness.start("withInitialCommand", [ "apple", "banana", "pear" ])
  await observe(t, harness, "stuff", "Got apple, banana, pear (3)", "it runs the initial command")
})

harnessTest("the iniial command sends a port message", async function(harness, t) {
  harness.getElmApp().ports.inform.subscribe(data => {
    t.deepEqual(data, { attributes: [ "surf", "ski" ] }, "it receives the initial port command")
  })
  await harness.start("withInitialPortCommand", [ "surf", "ski" ])
})

harnessTest("a message is sent in response to a message that is received", async function(harness, t) {
  await harness.start("default")
  harness.getElmApp().ports.inform.subscribe(data => {
    harness.getElmApp().ports.triggerStuff.send({ name: "Dr. Cool" })
  })
  await harness.runSteps("inform")
  await observe(t, harness, "name", "Dr. Cool", "it finds the name updated after the message is received")
})

harnessTest("the setup configures the context to stub an HTTP request", async function(harness, t) {
  await harness.start("withStub", { thing: "trees", count: 17 })
  await harness.runSteps("requestStuff")
  await observe(t, harness, "stuff", "Got trees (17)", "it observes that the stubbed response was processed")
})
