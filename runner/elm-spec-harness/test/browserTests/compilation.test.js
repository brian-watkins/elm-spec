import { prepareHarness } from "../../src";
import test from "fresh-tape"
import "./helpers"

test("compilation error", function(t) {
  t.throws(() => { prepareHarness("CompilationError.BadHarness") }, /Compilation error!/, "it throws an exception when the harness module cannot be compiled")
  t.end()
})