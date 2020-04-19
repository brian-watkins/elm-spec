const { JSDOM } = require("jsdom");
const { Compiler, SuiteRunner, ElmContext } = require('elm-spec-core')

module.exports = class JSDOMSpecRunner {
  async start() {}

  async run(reporter, compilerOptions, runnerOptions) {
    const dom = this.getDom()

    const context = new ElmContext(dom.window)

    await reporter.performAction("Compiling Elm ... ", "Done!", async () => {
      return this.prepareElm(dom, compilerOptions)
    })

    await this.execute(context, reporter, runnerOptions)
  }

  async stop() {}

  getDom() {
    return new JSDOM(
      "<html><head><base href='http://elm-spec'></head><body></body></html>",
      { pretendToBeVisual: true,
        runScripts: "dangerously",
        url: "http://elm-spec"
      }
    )
  }

  prepareElm(dom, options) {
    const compiler = new Compiler(options)
    const code = compiler.compile()
    dom.window.eval(code)
    return dom.window.hasOwnProperty("Elm")
  }

  async execute(context, reporter, options) {
    await new Promise((resolve) => {
      new SuiteRunner(context, reporter, options)
        .on('complete', resolve)
        .runAll()
    })
  }
}