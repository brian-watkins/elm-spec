const Koa = require('koa')
const serve = require('koa-static')
const Router = require('@koa/router');
const mount = require('koa-mount');
const websockify = require('koa-websocket');
const koaBody = require('koa-body');
const views = require('koa-views');
const fs = require('fs');
const path = require('path')

module.exports = class SpecServer {

  constructor(fileLoader, options) {
    this.fileLoader = fileLoader
    this.app = websockify(new Koa(), {})
    this.configureSpecsRoutes(options.cssFiles)
    this.configureConnectRoute()
    this.configureFixtureRoutes(options.cssFiles)
  }

  async start(host) {
    return new Promise((resolve) => {
      this.server = this.app.listen(0, host, resolve)
    })
  }

  host() {
    const address = this.server.address()
    return `http://${address.address}:${address.port}`
  }

  onConnect(handler) {
    this.handleConnection = handler
  }

  onRequestSpecs(handler) {
    this.provideSpecs = handler
  }

  onEvent(handler) {
    this.handleEvent = handler
  }

  isConnected() {
    return this.websocket
  }

  send(message) {
    if (this.isConnected()) {
      this.websocket.send(JSON.stringify(message))
    }
  }

  stop() {
    this.websocket.terminate()
    this.websocket = null
    this.server.close()
  }

  configureSpecsRoutes(cssFiles) {
    const specRoutes = new Koa()

    specRoutes.use(views(path.join(__dirname, 'remote'), {
      map: {
        html: 'mustache'
      }
    }))

    const router = new Router()
      .get("/", (ctx) => {
        return ctx.render("index.html", {
          cssFiles: cssFiles.map((el, index) => index)
        })
      })
      .get("specs.js", (ctx) => {
        ctx.set("Content-Type", "application/javascript")
        ctx.body = this.provideSpecs()
      })

    specRoutes.use(router.routes())

    specRoutes.use(serve(path.join(__dirname, 'remote')))

    this.app.use(mount("/specs/", specRoutes))
  }

  configureConnectRoute() {
    const socketRouter = new Router()
    socketRouter.get("/connect", (ctx) => {
      this.websocket = ctx.websocket

      this.websocket.on('message', message => {
        const event = JSON.parse(message.toString())
        this.handleEvent(event)
      })

      this.handleConnection()
    })
    this.app.ws.use(socketRouter.routes())
  }

  configureFixtureRoutes(cssFiles) {
    this.app.use(koaBody())

    const router = new Router()
    router
      .post('/fixture/files', async (ctx) => {
        const fileRequest = ctx.request.body
        const file = await this.fileLoader.handleFileLoad(fileRequest)
        ctx.body = file
      })
      .get('/fixture/styles/:index', async (ctx) => {
        const cssPath = cssFiles[ctx.params.index]
        if (cssPath) {
          const absolutePath = path.resolve(process.cwd(), cssPath)
          const css = fs.readFileSync(absolutePath)
          ctx.set("Content-Type", "text/css")
          ctx.body = css
        }
      })

    this.app.use(router.routes())
  }
}