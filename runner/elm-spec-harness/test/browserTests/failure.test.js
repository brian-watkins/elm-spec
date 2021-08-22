import { startHarness } from "../../src/HarnessRunner"
import test from "tape"
import { expectRejection, harnessTestGenerator } from "./helpers"

test("harness module does not exist", function(t) {
  t.throws(() => { startHarness("No.Module.That.Exists") }, /Module No.Module.That.Exists does not exist!/, "it throws an exception when the module does not exist")
  t.end()
})

const harnessTest = harnessTestGenerator("Basic.Harness")

harnessTest("setup doesn't exist", async function(harness, t) {
  await expectRejection(t, () => harness.start("some-setup-that-does-not-exist"), (message) => {
    t.equals(message, "No setup has been exposed with the name some-setup-that-does-not-exist", "it rejects the promise with an error")
  })
})