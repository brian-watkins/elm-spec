import test from "tape"
import * as harness from "../../src/HarnessRunner"
import { observe } from "./helpers"

test("the setup specifies an initial location", async function(t) {
  await harness.setup("withLocation", "http://test.com/funPage")
  await observe(t, "title", "On the fun page!", "it observes that the initial location was processed")
})

test("a step causes a location change", async function(t) {
  await harness.setup("withLocation", "http://test.com/")
  await harness.runSteps("gotoAwesome")
  await observe(t, "title", "On the awesome page!", "the updated location was processed")
})

test("clicking a link causes a location change", async function(t) {
  await harness.setup("withLocation", "http://test.com/")
  await harness.runSteps("clickLinkToChangeLocation")
  await observe(t, "title", "On the super page!", "the location change request was processed")
})

test("loading an external url", async function(t) {
  await harness.setup("withLocation", "http://test.com/")
  await harness.runSteps("clickLinkToLeaveApp")
  await observe(t, "location", "http://fun-times.com/fun.html", "the external location is recorded")
  await observe(t, "pageText", "http://fun-times.com/fun.html", "the app shows it has navigated to an external page")
})

test("loading an external url from a port", async function(t) {
  await harness.setup("withLocation", "http://test.com/")
  harness.getElmApp().ports.triggerLocationChange.send("http://fun-place.com/cool.html")
  await observe(t, "pageText", "http://fun-place.com/cool.html", "the app shows it has navigated to the external page specified by the port")
})