const { chromium } = require('playwright')
const { bundleRunnerCode } = require('./bundleHelpers')
const { Compiler } = require('elm-spec-core')
const path = require('path')

const specSrcDir = path.join(__dirname, "..", "src")

const compiler = new Compiler({
  cwd: specSrcDir,
  specPath: "./Specs/*Spec.elm",
  logLevel: Compiler.LOG_LEVEL.SILENT
})

before(async () => {
  global.browser = await chromium.launch()
  const context = await browser.newContext()
  global.page = await context.newPage()

  const bundle = await bundleRunnerCode()

  const compiledCode = compiler.compile()

  page.on('console', async (msg) => {
    const logParts = await Promise.all(msg.args().map((arg) => arg.jsonValue()))
    console.log(...logParts)
  });

  await page.evaluate(bundle)
  await page.evaluate(compiledCode)
})

after(async () => {
  await browser.close()
})
