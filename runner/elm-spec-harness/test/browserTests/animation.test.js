import { harnessTestGenerator, observe } from "./helpers"

const harnessTest = harnessTestGenerator("Animation.Harness")

harnessTest("lingering animation frames", async function (harness, t) {
  const scenario = await harness.startScenario("default")
  await scenario.runSteps("nextAnimationFrame")
  await observe(t, scenario, "elements", 1, "it finds one element after an animation frame")
  harness.stopScenario()

  const secondScenario = await harness.startScenario("default")
  await secondScenario.runSteps("nextAnimationFrame")
  await observe(t, secondScenario, "elements", 1, "it finds one element after an animation frame on the next setup")
})
