import { harnessTestGenerator, captureLogs, captureObservations } from "./helpers"

const harnessTest = harnessTestGenerator("Basic.Harness")

harnessTest("handling an observation", async function(harness, t) {
  const observations = await captureObservations(async () => {
    const scenario = await harness.startScenario("default")
    await scenario.runSteps("click", 5)
    await scenario.observe("count", "15 clicks!", { t, message: "this should fail" })
  })
  
  t.true(observations.length === 1 && observations[0].summary === "REJECTED", "it handles the rejected observation")
})

harnessTest("handling logs", async function(harness, t) {
  const logs = await captureLogs(async () => {
    const scenario = await harness.startScenario("default")
    await scenario.runSteps("logTitle")
  })
  
  t.equal(logs[0][0].statement, "HTML for element: #title", "it handles the expected log")
})