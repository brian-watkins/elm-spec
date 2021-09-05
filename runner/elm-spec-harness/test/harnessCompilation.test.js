import test from "fresh-tape";
import { runCompilationTests } from "./runTests"
import { expectPassingTest } from "./helpers"

runCompilationTests((testOutput) => {
  test("compilation error", function (t) {
    expectPassingTest(t, testOutput, "it throws an exception when the harness module cannot be compiled", "prepareHarness throws an error if the module cannot be compiled")
    t.end()
  })
})
