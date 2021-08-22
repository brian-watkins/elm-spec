import { harnessTestGenerator, getLogs, getRejectedObservations } from "./helpers"

const harnessTest = harnessTestGenerator("Basic.Harness")

harnessTest("handling an observation", async function(harness, t) {
  const scenario = await harness.start("default")
  await scenario.runSteps("click", 5)
  await scenario.observe("count", "15 clicks!", { t, message: "this should fail" })
  t.equal(getRejectedObservations().length, 1, "it handles the rejected observation")
})

harnessTest("handling logs", async function(harness, t) {
  const scenario = await harness.start("default")
  await scenario.runSteps("logTitle")
  t.equal(getLogs()[0][0].statement, "HTML for element: #title", "it handles the expected log")
})