import { onFinish } from "tape"
import * as runner from "../../src/HarnessRunner"

export async function observe(t, name, actual, message) {
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
