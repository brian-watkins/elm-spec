import { harnessTestGenerator, observe } from "./helpers"

const harnessTest = harnessTestGenerator("Basic.Harness")

harnessTest("initial state of app", async function (harness, t) {
  const scenario = await harness.startScenario("withName", { name: "Professor Strange" })
  await observe(t, scenario, "name", "Professor Strange", "it finds the configured default name")
  await observe(t, scenario, "attributes", [ "cool", "fun" ], "it finds the default attributes")
})

harnessTest("the view updates", async function(harness, t) {
  const scenario = await harness.startScenario("default")
  await scenario.runSteps("click", 5)
  await observe(t, scenario, "count", "5 clicks!", "it counts the number of clicks")
  await scenario.runSteps("click", 2)
  await observe(t, scenario, "count", "7 clicks!", "it counts the number of clicks again")
})

harnessTest("the app is reset", async function(harness, t) {
  const scenario = await harness.startScenario("default")
  await observe(t, scenario, "count", "0 clicks!", "it resets the app at the beginning of each test")
})

harnessTest("a message is sent to the app that updates the model and runs a command", async function(harness, t) {
  const scenario = await harness.startScenario("default")
  harness.getElmApp().ports.triggerStuff.send({ name: "Super cool dude" })
  await scenario.wait()
  await observe(t, scenario, "name", "Super cool dude", "it finds the updated name")
  await observe(t, scenario, "stuff", "Got apples (91)", "it observes that the request triggered by the port message was processed")
})

harnessTest("the iniial command sends an HTTP request", async function(harness, t) {
  const scenario = await harness.startScenario("withInitialCommand", [ "apple", "banana", "pear" ])
  await observe(t, scenario, "stuff", "Got apple, banana, pear (3)", "it runs the initial command")
})

harnessTest("the iniial command sends a port message", async function(harness, t) {
  harness.getElmApp().ports.inform.subscribe(data => {
    t.deepEqual(data, { attributes: [ "surf", "ski" ] }, "it receives the initial port command")
  })
  await harness.startScenario("withInitialPortCommand", [ "surf", "ski" ])
})

harnessTest("a message is sent in response to a message that is received", async function(harness, t) {
  const scenario = await harness.startScenario("default")
  harness.getElmApp().ports.inform.subscribe(data => {
    harness.getElmApp().ports.triggerStuff.send({ name: "Dr. Cool" })
  })
  await scenario.runSteps("inform")
  await observe(t, scenario, "name", "Dr. Cool", "it finds the name updated after the message is received")
})

harnessTest("the setup configures the context to stub an HTTP request", async function(harness, t) {
  const scenario = await harness.startScenario("withStub", { thing: "trees", count: 17 })
  await scenario.runSteps("requestStuff")
  await observe(t, scenario, "stuff", "Got trees (17)", "it observes that the stubbed response was processed")
})
