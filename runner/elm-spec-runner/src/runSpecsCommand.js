const { SuiteRunner } = require('elm-spec-core')
const Compiler = require('elm-spec-core/compiler')


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

    const results = await this.runSpecs(runOptions)

    if (shouldWatch(watchOptions) || (browserOptions.visible && runOptions.endOnFailure)) {
      return { status: "Watching" }
    }

    await this.runner.stop()

    return summarizedResults(results)
  }

  async runSpecs(runOptions) {
    const compiledElm = await this.reporter.performAction("Compiling Elm ... ", "Done!", async () => {
      const code = this.compiler.compile()
      return {
        isOk: this.compiler.status() === Compiler.STATUS.COMPILATION_SUCCEEDED,
        value: code
      }
    })

    return await this.runner.run(runOptions, compiledElm, this.reporter)
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

const summarizedResults = (results) => {
  const summarized = { status: SuiteRunner.STATUS.OK, accepted: 0, rejected: 0, skipped: 0 }

  for (const result of results) {
    if (result.status === SuiteRunner.STATUS.ERROR) {
      return result
    }
    summarized.accepted += result.accepted
    summarized.rejected += result.rejected
    summarized.skipped += result.skipped
  }

  return summarized
}