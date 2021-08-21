import { startHarness } from "../../src/HarnessRunner"
import test from "tape"

test("harness module does not exist", function(t) {
  t.throws(() => { startHarness("No.Module.That.Exists") }, /Module No.Module.That.Exists does not exist!/, "it throws an exception when the module does not exist")
  t.end()
})
