import test from "fresh-tape"
import HarnessController from "../../src/controller"
import { expectError } from "./helpers"

test("harness version does not match elm-spec-core version", async function(t) {
  const controller = new HarnessController()
  const harness = controller.prepareHarness("Version.Harness", 27)
  await expectError(t, () => harness.startScenario("some-setup"), (message) => {
    t.equals(message, "elm-spec requires elm-spec-core at version '0.x' - but your elm-spec-core version is '27.x' - Check your JavaScript runner and upgrade to make the versions match.", "it rejects the start promise with an error when the versions are out of sync")
  })
})

