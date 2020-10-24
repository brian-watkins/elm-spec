const path = require('path')
const fs = require('fs')


module.exports = class RunSpecsCommand {
  constructor(compiler, runner, reporter, fileWatcher) {
    this.compiler = compiler
    this.runner = runner
    this.reporter = reporter
    this.fileWatcher = fileWatcher
  }
  
  async execute({ browserOptions, runOptions, watchOptions }) {
    await this.runner.start(browserOptions)

    if (shouldWatch(watchOptions)) {
      this.logList("Watching Files", watchOptions.globs)

      this.fileWatcher.watch(watchOptions.globs, async (path) => {
        this.log(`File changed: ${path}`)
        this.reporter.reset()
        await this.runSpecs(runOptions)
      })
    }

    await this.runSpecs(runOptions)

    if (shouldWatch(watchOptions) || (browserOptions.visible && runOptions.endOnFailure)) {
      return
    }

    await this.runner.stop()
  }

  async runSpecs(runOptions) {
    const compiledElm = await this.reporter.performAction("Compiling Elm ... ", "Done!", async () => {
      return this.compiler.compile()
    })

    await this.runner.run(runOptions, compiledElm, this.reporter)
  }

  log(message) {
    this.reporter.printLine(message)
    this.reporter.printLine()
  }

  logList(message, details) {
    this.log(message)
    if (details) {
      details.forEach((detail) => {
        this.reporter.printLine(`- ${detail}`)
      })
    }
    this.reporter.printLine()
  }
}

const shouldWatch = (options) => {
  return options.globs.length > 0
}
