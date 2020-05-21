const { bundleRunnerCode } = require('./bundleHelpers')
const { Compiler } = require('elm-spec-core')
const JSDOMSpecRunner = require('../../runner/elm-spec-runner/src/jsdomSpecRunner')
const FileLoader = require('../../runner/elm-spec-runner/src/fileLoader')
const path = require('path')

const specSrcDir = path.join(__dirname, "..", "src")

const fileLoader = new FileLoader(specSrcDir)
const runner = new JSDOMSpecRunner(fileLoader)

before(async () => {
  const dom = runner.getDom()

  global.page = dom

  const bundle = await bundleRunnerCode()
  dom.window.eval(bundle)

  runner.prepareElm(dom, {
    cwd: specSrcDir,
    specPath: "./Specs/*Spec.elm",
    logLevel: Compiler.LOG_LEVEL.QUIET
  })
})

after(() => {
  page.window.close()
})