const { bundleRunnerCode } = require('./bundleHelpers')
const { Compiler } = require('elm-spec-core')
const BrowserSpecRunner = require('../../runner/elm-spec-runner/src/browserSpecRunner')
const FileLoader = require('../../runner/elm-spec-runner/src/fileLoader')
const path = require('path')

const specSrcDir = path.join(__dirname, "..", "src")

const fileLoader = new FileLoader(specSrcDir)
const browserSpecRunner = new BrowserSpecRunner("chromium", fileLoader)

before(async () => {
  await browserSpecRunner.start({
    visible: false
  })
  global.page = await browserSpecRunner.getPage()

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
