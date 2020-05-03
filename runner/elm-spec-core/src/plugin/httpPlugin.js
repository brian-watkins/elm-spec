const MockXHR = require('xhr-mock/lib/MockXMLHttpRequest').default
const stubFor = require('xhr-mock/lib/createMockFunction').default
const BlobReader = require('../blobReader')
const { report, line } = require('../report')

const fakeServerForGlobalContext = function(window) {
  window.XMLHttpRequest = new Proxy(MockXHR, {
    construct: (target, args) => {
      const request = requestProxy(new target(...args))
      request.req.xhr = () => { return request }
      return request
    }
  })
  return window.XMLHttpRequest
}

const requestProxy = function(request) {
  return new Proxy(request, {
    get: (target, prop) => {
      if (prop === "send") {
        return (body) => {
          let safeBody = body
          if (body instanceof DataView) {
            safeBody = new Blob([body])
          }
          target.send(safeBody)
        }
      }
      const val = target[prop]
      return typeof val === "function"
        ? (...args) => val.apply(target, args)
        : val;
    }
  })
}

module.exports = class HttpPlugin {
  constructor(context) {
    this.server = fakeServerForGlobalContext(context.window)
    this.server.errorCallback = function() {}
    this.reset()
  }

  reset() {
    this.resetHistory()
    this.resetStubs()
  }

  resetHistory() {
    this.requests = []
  }

  resetStubs() {
    this.server.removeAllHandlers()
    this.server.addHandler(this.recordRequests())
  }

  recordRequests() {
    return (request) => {
      this.requests.push(request)
    }
  }

  handle(specMessage, out, next, abort) {
    switch (specMessage.name) {
      case "clear-history": {
        this.resetHistory()
        break
      }
      case "stub": {
        this.resetStubs()

        for (const stub of specMessage.body) {
          try {
            this.setupStub(stub, this.uriDescriptor(stub), out)
          } catch (err) {
            abort(err.report)
            break
          }
        }

        break
      }
      case "fetch-requests": {
        const route = specMessage.body
        let requestPromises = []

        switch (route.uri.type) {
          case "EXACT": {
            requestPromises = this.findRequests(route, (url) => {
              return url === route.uri.value
            })

            break
          }
          case "REGEXP": {
            try {
              const regex = new RegExp(route.uri.value)
              requestPromises = this.findRequests(route, (url) => {
                return regex.test(url)
              })
            } catch (err) {
              abort(report(
                line("Unable to parse regular expression used to observe requests", `/${route.uri.value}/`)
              ))
              return
            }
          }
        }

        Promise.all(requestPromises)
          .then((requests) => {
            out({
              home: "_http",
              name: "requests",
              body: requests
            })    
          })

        break
      }
      default:
        console.log("Unknown Http message", specMessage)
    }
  }

  uriDescriptor(stub) {
    switch (stub.route.uri.type) {
      case "EXACT": {
        return stub.route.uri.value
      }
      case "REGEXP": {
        try {
          return new RegExp(stub.route.uri.value)
        } catch (err) {
          const error = new Error()
          error.report = report(
            line("Unable to parse regular expression for stubbed route", `/${stub.route.uri.value}/`)
          )
          throw error
        }
      }
    }
  }

  setupStub(stub, uriDescriptor, out) {
    this.server.addHandler(stubFor(stub.route.method, uriDescriptor, (request, response) => {
      if (stub.shouldRespond) {
        if (stub.error === "network") {
          return Promise.reject(new Error())
        } else if (stub.error === "timeout") {
          request.xhr().listeners.timeout[0]()
          request.xhr().abort()
        } else {
          return response.status(stub.status).headers(stub.headers).body(stub.body)
        }
      } else {
        request.xhr().abort()
        out({home: "_http", name: "abstained", body: null})
      }
    }))
  }

  findRequests(route, matchUrl) {
    return this.requests
      .filter(request => {
        if (route.method !== "ANY" && request.method() !== route.method) return false
        return matchUrl(request.url().toString())
      })
      .map(buildRequest)
  }
}

const buildRequest = (request) => {
  return buildRequestBody(request.body())
    .then((requestBody) => {
      return {
        methpd: request.method(),
        url: request.url().toString(),
        headers: request.headers(),
        body: requestBody
      }
    })
}

const buildRequestBody = (requestBody) => {
  if (!requestBody) {
    return Promise.resolve(null)
  }

  if (requestBody instanceof File) {
    return Promise.resolve({
      type: "file",
      content: requestBody
    })
  }

  if (requestBody instanceof Blob) {
    return new BlobReader(requestBody).readIntoArray()
      .then((data) => {
        return { type: "bytes", data }
      })
  }

  return Promise.resolve({
    type: "string",
    content: requestBody
  })
}
