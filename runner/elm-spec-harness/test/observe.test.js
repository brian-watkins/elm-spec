const test = require("tape")
const browserify = require('browserify')
const { chromium } = require('playwright');
const path = require("path")
const fs = require("fs")
const Harness = require("../src/Harness")

test('observe', async function (t) {
  const output = await runTestInBrowser("passingDisplayTests.js")
  expectContains(t, output, "ok 1 it finds the default name", "an expectation about the default model passes")
})

const runTestInBrowser = async (testFile) => {
  const testCode = await bundleBrowserTests(testFile)

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

  // load the browser adapter
  const adapter = fs.readFileSync("./src/browserAdapter.js")
  await page.evaluate(adapter)
  
  // then load the compiled js
  const harness = new Harness()
  const compiledHarness = harness.compile("./src/Basic.elm")
  await page.evaluate(compiledHarness)

  // load/start the test in playwright
  await Promise.all([waitForTestsToComplete, page.evaluate(testCode)])

  await browser.close()

  return output
}

const expectContains = (t, list, item, success) => {
  if (list.includes(item)) {
    t.pass(success)
  } else {
    t.fail(`Expected [ ${list} ] to include: ${item}`)
  }
}

const bundleBrowserTests = (testFile) => {
  const b = browserify();
  b.add(path.join(__dirname, "browserTests", testFile));

  return new Promise((resolve, reject) => {
    let bundle = ''
    const stream = b.bundle()
    stream.on('data', function (data) {
      bundle += data.toString()
    })
    stream.on('end', function () {
      resolve(bundle)
    })
  })
}
