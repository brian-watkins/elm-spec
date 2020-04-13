const { chromium } = require('playwright')
const browserify = require('browserify');
const { Compiler } = require('elm-spec-core')
const path = require('path')

const specSrcDir = path.join(__dirname, "..", "src")

const compiler = new Compiler({
  cwd: specSrcDir,
  specPath: "./Specs/*Spec.elm"
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

const bundleRunnerCode = () => {
  const b = browserify();
  b.add(path.join(__dirname, "browserRunner.js"));
  
  return new Promise((resolve, reject) => {  
    let bundle = ''
    const stream = b.bundle()
    stream.on('data', function(data) {
      bundle += data.toString()
    })
    stream.on('end', function() {
      resolve(bundle)
    })
  })
}
