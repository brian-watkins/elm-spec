import test from "tape";
import { chromium } from 'playwright';
import { join } from "path";
import Harness from "../src/Harness";
import { serve } from "esbuild";
import NodeModulesPolyfill from "@esbuild-plugins/node-modules-polyfill";
import GlobalsPolyfills from '@esbuild-plugins/node-globals-polyfill'

test('observe', async function (t) {
  const output = await runTestInBrowser("passingDisplayTests.js")
  expectPassingTest(t, output, "it finds the default attributes", "a test observing the default model passes")
  expectPassingTest(t, output, "it finds the configured default name", "a test passes that configures the setup")
  expectPassingTest(t, output, "it counts the number of clicks", "a test passes that runs steps and changes the model")
  expectPassingTest(t, output, "it counts the number of clicks again", "a test passes that runs steps and changes the model again after an observation")
  expectPassingTest(t, output, "it resets the app at the beginning of each test", "a test passes that depends on the app model being reset")
  expectPassingTest(t, output, "it finds the updated name", "a test passes that involves sending a message to the app")
  expectPassingTest(t, output, "it receives the expected message", "a test passes that receives a message from the app")
  expectPassingTest(t, output, "it finds the name updated after the message is received", "a test passes that sends a message to the app in response to receiving one")
})

const runTestInBrowser = async (testFile) => {
  const serveResult = await serveTests(testFile)

  const browser = await chromium.launch({
    headless: false
  })
  const page = await browser.newPage()

  let output = []
  
  const waitForTestsToComplete = new Promise((resolve) => {
    page.on("console", (message) => {
      if (message.text() === "END") {
        resolve()
      } else {
        output.push(message.text())
      }
    })
  })

  // then load the compiled js (also loads the browser adapter)
  const harness = new Harness()
  const compiledHarness = harness.compile("./src/BasicHarness.elm")
  await page.evaluate(compiledHarness)

  // load/start the test in playwright
  await Promise.all([waitForTestsToComplete, page.addScriptTag({ url: "http://localhost:8888/tests.js" })])

  await browser.close()

  serveResult.stop()

  return output
}

const expectPassingTest = (t, output, testName, message) => {
  expectListItemMatches(t, output, `^ok \\d+ ${testName}$`, message)
}

const expectListItemMatches = (t, list, regex, success) => {
  if (list.find(element => element.match(regex))) {
    t.pass(success)
  } else {
    t.fail(`Expected [ ${list} ] to have an item matching: ${regex}`)
  }
}

const expectContains = (t, list, item, success) => {
  if (list.includes(item)) {
    t.pass(success)
  } else {
    t.fail(`Expected [ ${list} ] to include: ${item}`)
  }
}

const serveTests = async (testFile) => {
  return serve({
    port: 8888
  }, {
    entryPoints: [ join(__dirname, "browserTests", testFile) ],
    bundle: true,
    outfile: "tests.js",
    define: { global: 'window', "__dirname": `"${__dirname}"` },
    plugins: [
      NodeModulesPolyfill(),
      GlobalsPolyfills({
        process: true
      })
    ]
  })
}
