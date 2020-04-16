const { JSDOM } = require("jsdom");
const { Compiler, SuiteRunner, ElmContext } = require('elm-spec-core')

module.exports = class JSDOMSpecRunner {
  async init() {
    this.dom = new JSDOM(
      "<html><head><base href='http://elm-spec'></head><body></body></html>",
      { pretendToBeVisual: true,
        runScripts: "dangerously",
        url: "http://elm-spec"
      }
    )

    this.context = new ElmContext(this.dom.window)
  }

  async run(reporter, compilerOptions, runnerOptions) {
    this.compile(compilerOptions)
    await this.execute(reporter, runnerOptions)
  }

  compile(options) {
    const compiler = new Compiler(options)
    const code = compiler.compile()
    this.dom.window.eval(code)
  }

  async execute(reporter, options) {
    await new Promise((resolve) => {
      new SuiteRunner(this.context, reporter, options)
        .on('complete', () => {
          if (reporter.hasError) {
            process.exit(1)
          }

          resolve()
        })
        .runAll()
    })
  }
}