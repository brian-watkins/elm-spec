const { bundleRunnerCode } = require('./bundleHelpers')
const { Compiler } = require('elm-spec-core')
const JSDOMSpecRunner = require('../../runner/elm-spec-runner/src/jsdomSpecRunner')
const path = require('path')

const specSrcDir = path.join(__dirname, "..", "src")

const compiler = new Compiler({
  cwd: specSrcDir,
  specPath: "./Specs/*Spec.elm",
  logLevel: Compiler.LOG_LEVEL.SILENT
})

before(async () => {
  const runner = new JSDOMSpecRunner()
  const dom = runner.getDom()

  global.page = dom

  const bundle = await bundleRunnerCode()
  dom.window.eval(bundle)

  const compiledCode = compiler.compile()
  dom.window.eval(compiledCode)
})
