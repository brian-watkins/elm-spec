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
      this.log("Watching Files", watchOptions.globs)

      this.fileWatcher.watch(watchOptions.globs, async (path) => {
        this.log("File Changed", path)
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

  log(statement, details) {
    this.reporter.log([{
      statement, 
      detail: Array.isArray(details) ? details.join("\n") : details
    }])
  }
}

const shouldWatch = (options) => {
  return options.globs.length > 0
}
