import { chromium } from 'playwright';
import { join } from "path";
import { serve } from "esbuild";
import Compiler from "elm-spec-core/src/compiler"
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
        if (process.env["DEBUG"]) {
          console.log(message.text())
        }
        output.push(message.text())
      }
    })
  })

  // load the compiled elm
  const compiler = new Compiler({
    cwd: "./test/browserTests/harness",
    specPath: "./src/**/Harness.elm",
    logLevel: Compiler.LOG_LEVEL.QUIET
  })
  const compiledHarness = compiler.compile()
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

  if (process.env["DEBUG"]) {
    return
  }

  outputHandler(testOutput)
}