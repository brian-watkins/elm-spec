const MockXHR = require('mock-xmlhttprequest')
const BlobReader = require('../blobReader')
const { report, line } = require('../report')

const createMockXhrRequestClass = function(context) {
  const MockXHRClass = MockXHR.newMockXhr()
  return new Proxy(MockXHRClass, {
    construct: (target, args) => {
      return requestProxy(context, new target(...args))
    }
  })
}

const requestProxy = function(context, request) {
  return new Proxy(request, {
    get: (target, prop) => {
      if (prop === "send") {
        return (body) => {
          let safeBody = body
          if (body instanceof DataView) {
            safeBody = new Blob([body])
          }
          context.timer.stopWaitingForStack()
          target.send(safeBody)
        }
      }
      if (prop === "getAllResponseHeaders") {
        return () => {
          const headers = target._response.headers.getHash()
          return Object.keys(headers).sort().reduce((result, name) => {
            const headerValue = headers[name];
            return `${result}${name.toLowerCase()}: ${headerValue}\r\n`;
          }, '')
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
    const MockXHRClass = createMockXhrRequestClass(context)
    this.server = new MockXHR.MockXhrServer(MockXHRClass, {})
    this.server.install(context.window)
    this.server.setDefault404()
    this.reset()
  }

  reset() {
    this.resetHistory()
    this.resetStubs()
  }

  resetHistory() {
    this.server._requests = []
  }

  resetStubs() {
    this.server._routes = {}
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
    this.server.addHandler(stub.route.method, uriDescriptor, (xhr) => {
      if (stub.error === "network") {
        xhr.setNetworkError()
      } else if (stub.error === "timeout") {
        xhr.setRequestTimeout()
      } else {
        switch (stub.progress.type) {
          case "sent":
            xhr.uploadProgress(stub.progress.transmitted)
            out({home: "_http", name: "handled", body: null})
            break
          case "received":
            xhr.setResponseHeaders(stub.headers)
            xhr.downloadProgress(stub.progress.transmitted, this.responseBodyLength(stub.body))
            out({home: "_http", name: "handled", body: null})
            break
          case "streamed":
            xhr.setResponseHeaders(stub.headers)
            xhr.downloadProgress(stub.progress.transmitted)
            out({home: "_http", name: "handled", body: null})
            break
          case "complete":
            xhr.respond(stub.status, stub.headers, this.responseBody(stub.body))
            break
        }
      }
    })
  }

  responseBody(body) {
    switch (body.type) {
      case "empty":
        return ""
      case "text":
        return body.content
      case "binary":
        return Uint8Array.from(body.content).buffer
    }
  }

  responseBodyLength(body) {
    switch (body.type) {
      case "empty":
        return 0
      case "text":
        return body.content.length
      case "binary":
        return body.content.length
    }
  }

  findRequests(route, matchUrl) {
    return this.server.getRequestLog()
      .filter(request => {
        if (route.method !== "ANY" && request.method !== route.method) return false
        return matchUrl(request.url)
      })
      .map(buildRequest)
  }
}

const buildRequest = (request) => {
  return buildRequestBody(request.body)
    .then((requestBody) => {
      return {
        methpd: request.method,
        url: request.url,
        headers: request.headers,
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
