import { chromium } from 'playwright';
import { join } from "path";
import { serve } from "esbuild";
import Compiler from "../compiler"
import NodeModulesPolyfill from "@esbuild-plugins/node-modules-polyfill";
import GlobalsPolyfills from '@esbuild-plugins/node-globals-polyfill'


const runTestInBrowser = async (compilerOptions, testEntry) => {
  const serveResult = await serveTests(testEntry)

  const browser = await chromium.launch({
    headless: !process.env["DEBUG"]
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
  const compiler = new Compiler(compilerOptions)
  const compiledHarness = compiler.compile()
  await page.evaluate(compiledHarness)

  // REVISIT: Is this the best way to register the file loading capability?
  await page.exposeFunction("_elm_spec_load_file", (options) => {
    return Promise.reject({ type: "file", path: options.path })
  })

  // load/start the test in playwright
  await Promise.all([waitForTestsToComplete, page.addScriptTag({ url: "http://localhost:8888/tests.js" })])

  await browser.close()

  serveResult.stop()

  return output
}

const serveTests = async (testEntry) => {
  return serve({
    port: 8888
  }, {
    entryPoints: [join(__dirname, "browserTests", testEntry)],
    bundle: true,
    outfile: "tests.js",
    define: { global: 'window', "__dirname": `"${__dirname}"` },
    plugins: [
      NodeModulesPolyfill(),
      GlobalsPolyfills({
        buffer: true
      })
    ]
  })
}

export async function runTests(outputHandler) {
  const testOutput = await runTestInBrowser({
    cwd: "./test/browserTests/harness",
    harnessPath: "./src/**/Harness.elm",
    logLevel: Compiler.LOG_LEVEL.QUIET
  }, "index.js")

  handleOutput(outputHandler, testOutput)
}

export async function runCompilationTests(outputHandler) {
  const testOutput = await runTestInBrowser({
    cwd: "./test/browserTests/harness",
    harnessPath: "./src/CompilationError/BadHarness.elm",
    logLevel: Compiler.LOG_LEVEL.SILENT
  }, "compilation.test.js")

  handleOutput(outputHandler, testOutput)
}

function handleOutput(outputHandler, testOutput) {
  if (process.env["DEBUG"]) {
    return
  }

  outputHandler(testOutput)
}
