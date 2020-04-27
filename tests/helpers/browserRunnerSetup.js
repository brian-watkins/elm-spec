const { bundleRunnerCode } = require('./bundleHelpers')
const { Compiler } = require('elm-spec-core')
const BrowserSpecRunner = require('../../runner/elm-spec-runner/src/browserSpecRunner')
const path = require('path')

const specSrcDir = path.join(__dirname, "..", "src")

const browserSpecRunner = new BrowserSpecRunner("chromium")

before(async () => {
  await browserSpecRunner.start({
    visible: false
  })
  global.page = await browserSpecRunner.getPage(specSrcDir)

  const bundle = await bundleRunnerCode()
  await page.evaluate(bundle)

  await browserSpecRunner.prepareElm(page, {
    cwd: specSrcDir,
    specPath: "./Specs/*Spec.elm",
    logLevel: Compiler.LOG_LEVEL.QUIET
  })
})

after(async () => {
  await browserSpecRunner.stop()
})
