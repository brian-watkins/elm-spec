import { chromium } from 'playwright';
import { join } from "path";
import Harness from "../src/Harness";
import { serve } from "esbuild";
import NodeModulesPolyfill from "@esbuild-plugins/node-modules-polyfill";
import GlobalsPolyfills from '@esbuild-plugins/node-globals-polyfill'


const runTestInBrowser = async () => {
  const serveResult = await serveTests()

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
  await Promise.all([waitForTestsToComplete, page.addScriptTag({ url: "http://localhost:8888/tests.js" }) ])

  await browser.close()

  serveResult.stop()

  return output
}

const serveTests = async () => {
  return serve({
    port: 8888
  }, {
    entryPoints: [ join(__dirname, "browserTests", "index.js") ],
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

export async function runTests(outputHandler) {
  const testOutput = await runTestInBrowser()
  outputHandler(testOutput)
}