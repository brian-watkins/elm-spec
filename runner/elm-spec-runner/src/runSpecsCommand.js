const path = require('path')
const fs = require('fs')


module.exports = class RunSpecsCommand {
  constructor(runner, reporter, fileWatcher) {
    this.runner = runner
    this.reporter = reporter
    this.fileWatcher = fileWatcher
  }
  
  async execute({ browserOptions, compilerOptions, runOptions, watchOptions }) {
    await this.runner.start(browserOptions)

    if (shouldWatch(watchOptions)) {
      this.logList("Watching Files", watchOptions.globs)

      this.fileWatcher.watch(watchOptions.globs, async (path) => {
        this.log(`File changed: ${path}`)
        this.reporter.reset()
        await this.runner.run(this.reporter, compilerOptions, runOptions)
      })
    }

    await this.runner.run(this.reporter, compilerOptions, runOptions)

    if (shouldWatch(watchOptions) || (browserOptions.visible && runOptions.endOnFailure)) {
      return
    }

    await this.runner.stop()
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
