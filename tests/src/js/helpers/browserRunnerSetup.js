const { bundleRunnerCode } = require('./bundleHelpers')
const { Compiler } = require('elm-spec-core')
const BrowserSpecRunner = require('../../../../runner/elm-spec-runner/src/browserSpecRunner')
const FileLoader = require('../../../../runner/elm-spec-runner/src/fileLoader')
const path = require('path')

const specSrcDir = path.join(__dirname, "..", "..", "..")

const fileLoader = new FileLoader(specSrcDir)
const browserSpecRunner = new BrowserSpecRunner("chromium", fileLoader)

before(async () => {
  await browserSpecRunner.start({
    visible: false
  })
  const context = await browserSpecRunner.getBrowserContext()
  global.page = await browserSpecRunner.getPage(context)

  const bundle = await bundleRunnerCode()
  await page.evaluate(bundle)

  const compiledElm = new Compiler({
    elmPath: "../node_modules/.bin/elm",
    cwd: specSrcDir,
    specPath: "./src/elm/Specs/*Spec.elm",
    logLevel: Compiler.LOG_LEVEL.QUIET
  }).compile()
  
  await browserSpecRunner.prepareElm(page, compiledElm)
})

after(async () => {
  await browserSpecRunner.stop()
})
