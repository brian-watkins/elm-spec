import test from "tape";
import { chromium } from 'playwright';
import { join } from "path";
import Harness from "../src/Harness";
import { serve } from "esbuild";
import NodeModulesPolyfill from "@esbuild-plugins/node-modules-polyfill";
import GlobalsPolyfills from '@esbuild-plugins/node-globals-polyfill'

test('observe', async function (t) {
  const output = await runTestInBrowser("passingDisplayTests.js")
  expectContains(t, output, "ok 1 it finds the default name", "a test observing the default model passes")
  expectContains(t, output, "ok 2 it finds the default attributes", "another test observing the default model passes")
  expectContains(t, output, "ok 3 it shows the page title in the view", "a test observing the view passes")
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
  const compiledHarness = harness.compile("./src/Basic.elm")
  await page.evaluate(compiledHarness)

  // load/start the test in playwright
  await Promise.all([waitForTestsToComplete, page.addScriptTag({ url: "http://localhost:8888/tests.js" })])

  await browser.close()

  serveResult.stop()

  return output
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
