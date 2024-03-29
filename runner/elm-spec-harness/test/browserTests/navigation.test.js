import { harnessTestGenerator, expectError, observe } from "./helpers"

const harnessTest = harnessTestGenerator("Navigation.Harness")

harnessTest("the setup specifies an initial location", async function(harness, t) {
  const scenario = await harness.startScenario("withLocation", "http://test.com/funPage")
  await observe(t, scenario, "title", "On the fun page!", "it observes that the initial location was processed")
})

harnessTest("a step causes a location change", async function(harness, t) {
  const scenario = await harness.startScenario("withLocation", "http://test.com/")
  await scenario.runSteps("gotoAwesome")
  await observe(t, scenario, "title", "On the awesome page!", "the updated location was processed")
})

harnessTest("clicking a link causes a location change", async function(harness, t) {
  const scenario = await harness.startScenario("withLocation", "http://test.com/")
  await scenario.runSteps("clickLinkToChangeLocation")
  await observe(t, scenario, "title", "On the super page!", "the location change request was processed")
})

harnessTest("loading an external url", async function(harness, t) {
  const scenario = await harness.startScenario("withLocation", "http://test.com/")
  await scenario.runSteps("clickLinkToLeaveApp")
  await observe(t, scenario, "location", "http://fun-times.com/fun.html", "the external location is recorded")
  await observe(t, scenario, "pageText", "http://fun-times.com/fun.html", "the app shows it has navigated to an external page")
})

harnessTest("loading an external url from a port", async function(harness, t) {
  const scenario = await harness.startScenario("withLocation", "http://test.com/")
  harness.getElmApp().ports.triggerLocationChange.send("http://fun-place.com/cool.html")
  await scenario.wait()
  await observe(t, scenario, "pageText", "http://fun-place.com/cool.html", "the app shows it has navigated to the external page specified by the port")
})

harnessTest("request url change without setting up navigation", async function(harness, t) {
  const scenario = await harness.startScenario("withNoNavigation")
  
  await expectError(t, () => scenario.runSteps("clickLinkToChangeLocation"), (error) => {
    t.equals(error.message, "A URL request occurred for an application, but no handler has been provided. Use Spec.Setup.forNavigation to set a handler.", "it rejects the url request runSteps promise with an error")
  })
})

harnessTest("change url without setting up navigation", async function(harness, t) {
  const scenario = await harness.startScenario("withNoNavigation")
  
  await expectError(t, () => scenario.runSteps("gotoAwesome"), (error) => {
    t.equals(error.message, "A URL change occurred for an application, but no handler has been provided. Use Spec.Setup.forNavigation to set a handler.", "it rejects the url change runSteps promise with an error")
  })
})
