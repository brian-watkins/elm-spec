import { harnessTestGenerator, getRejectedObservations } from "./helpers"

const harnessTest = harnessTestGenerator("Basic.Harness")

harnessTest("handling an observation", async function(harness, t) {
  await harness.start("default")
  await harness.runSteps("click", 5)
  await harness.observe("count", "15 clicks!", { t, message: "this should fail" })
  t.equal(getRejectedObservations().length, 1, "it handles the rejected observation")
})
