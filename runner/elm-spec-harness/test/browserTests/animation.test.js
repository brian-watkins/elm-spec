import { harnessTestGenerator, observe } from "./helpers"

const harnessTest = harnessTestGenerator("Animation.Harness")

harnessTest("lingering animation frames", async function (harness, t) {
  await harness.start("default")
  await harness.runSteps("nextAnimationFrame")
  await observe(t, harness, "elements", 1, "it finds one element after an animation frame")

  await harness.start("default")
  await harness.runSteps("nextAnimationFrame")
  await observe(t, harness, "elements", 1, "it finds one element after an animation frame on the next setup")
})
