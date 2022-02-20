const Koa = require('koa')
const serve = require('koa-static')
const Router = require('@koa/router');
const mount = require('koa-mount');
const websockify = require('koa-websocket');
const koaBody = require('koa-body');
const path = require('path')
const chalk = require('chalk')

module.exports = class RemoteSpecRunner {

  constructor(fileLoader) {
    this.fileLoader = fileLoader
  }

  async start(options) {
    const app = websockify(new Koa(), {})
    this.app = app

    const staticFiles = new Koa()
    staticFiles.use(serve(path.join(__dirname, 'remote')))
    
    app.use(mount("/specs/", staticFiles))
    
    const socketRouter = new Router()
    socketRouter.get("/connect", (ctx) => {
      this.handleSocketConnection(ctx.websocket)
      this.websocket = ctx.websocket
    })
    app.ws.use(socketRouter.routes())

    app.use(koaBody())

    const router = new Router()
    router.get('/specs/specs.js', (ctx) => {
      ctx.set("Content-Type", "application/javascript")
      ctx.body = this.compiledSpecs
    })
    router.post('/files', async (ctx) => {
      const fileRequest = ctx.request.body
      const file = await this.fileLoader.handleFileLoad(fileRequest)
      ctx.body = file
    })
    app.use(router.routes())
    
    return new Promise((resolve) => {
      this.server = app.listen(0, "127.0.0.1", resolve)
    })
  }

  handleSocketConnection(websocket) {
    websocket.on('message', message => {
      const event = JSON.parse(message.toString())

      switch (event.action) {
        case "reporter_start":
          this.reporter.startSuite()
          break
        case "reporter_observe":
          this.reporter.record(event.observation)
          break
        case "reporter_log":
          this.reporter.log(event.report)
          break
        case "reporter_error":
          this.reporter.error(event.error)
          break
        case "reporter_finished":
          this.reporter.finish()
          break
        case "specs-finished":
          this.specsFinished([event.results])
          break
      }
    })

    websocket.send(JSON.stringify({
      action: "run-specs",
      options: this.runOptions
    }))
  }

  async run(runOptions, compiledSpecs, reporter) {
    this.runOptions = runOptions
    this.runOptions.parallelSegments = 1
    this.compiledSpecs = compiledSpecs
    this.reporter = reporter

    if (this.websocket) {
      this.websocket.send(JSON.stringify({
        action: "reload-specs"
      }))
    } else {
      this.reporter.info(`Visit ${chalk.cyan(this.specsURL())} to run your specs!`)
    }
    
    return new Promise((resolve) => {
      this.specsFinished = resolve
    })
  }

  specsURL() {
    const address = this.server.address()
    return `http://${address.address}:${address.port}/specs/`
  }

  async stop() {
    this.websocket.send(JSON.stringify({
      action: "close"
    }))
    this.websocket.terminate()
    this.server.close()
  }
}