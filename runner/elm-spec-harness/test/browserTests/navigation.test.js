import test from "tape"
import * as harness from "../../src/HarnessRunner"
import { observe } from "./helpers"

test("the setup specifies an initial location", async function(t) {
  await harness.setup("withLocation", "http://test.com/funPage")
  await observe(t, "title", "On the fun page!", "it observes that the initial location was processed")
})
