import { harnessTestGenerator, observe } from "./helpers"

const harnessTest = harnessTestGenerator("Navigation.Harness")

harnessTest("the setup specifies an initial location", async function(harness, t) {
  await harness.start("withLocation", "http://test.com/funPage")
  await observe(t, harness, "title", "On the fun page!", "it observes that the initial location was processed")
})

harnessTest("a step causes a location change", async function(harness, t) {
  await harness.start("withLocation", "http://test.com/")
  await harness.runSteps("gotoAwesome")
  await observe(t, harness, "title", "On the awesome page!", "the updated location was processed")
})

harnessTest("clicking a link causes a location change", async function(harness, t) {
  await harness.start("withLocation", "http://test.com/")
  await harness.runSteps("clickLinkToChangeLocation")
  await observe(t, harness, "title", "On the super page!", "the location change request was processed")
})

harnessTest("loading an external url", async function(harness, t) {
  await harness.start("withLocation", "http://test.com/")
  await harness.runSteps("clickLinkToLeaveApp")
  await observe(t, harness, "location", "http://fun-times.com/fun.html", "the external location is recorded")
  await observe(t, harness, "pageText", "http://fun-times.com/fun.html", "the app shows it has navigated to an external page")
})

harnessTest("loading an external url from a port", async function(harness, t) {
  await harness.start("withLocation", "http://test.com/")
  harness.getElmApp().ports.triggerLocationChange.send("http://fun-place.com/cool.html")
  await observe(t, harness, "pageText", "http://fun-place.com/cool.html", "the app shows it has navigated to the external page specified by the port")
})