import test, { onFinish } from "tape"
import HarnessRunner from "../../src/HarnessRunner"

test("initial state of app", async function(t) {
  // initialize the spec harness
  const runner = new HarnessRunner()
  
  // run the setup
  runner.setup()
  
  // run the observer
  const titleObservation = await runner.observe("name", "Brian")
  if (titleObservation.summary === "ACCEPTED") {
    t.pass("it finds the default name")
  } else {
    t.fail("Failed! " + titleObservation.report)
  }
})

onFinish(() => {
  console.log("END")
})