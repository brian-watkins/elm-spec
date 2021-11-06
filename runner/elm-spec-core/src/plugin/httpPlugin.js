const MockXHR = require('mock-xmlhttprequest')
const BlobReader = require('../blobReader')
const { report, line } = require('../report')
const yaml = require('js-yaml')
const OpenApiValidator = require('./openApiValidator')

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
          context.timer.requestHold()
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
    this.context = context
    this.window = context.window
    const MockXHRClass = createMockXhrRequestClass(context)
    this.server = new MockXHR.MockXhrServer(MockXHRClass, {})
    this.server.install(context.window)
    this.server.setDefaultHandler((request) => {
      this.context.timer.releaseHold()
      request.respond(404)
    })
    this.reset()
  }

  reset() {
    this.resetHistory()
    this.resetStubs()
    // should set schema to null here, but probably need a test ...
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
            this.setupStub(stub, this.uriDescriptor(stub), out, abort)
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
      case "validate": {
        console.log("Got a contract to use:", specMessage.body.path)

        // This needs to do something like request a timer hold
        // Or, we need to call complete when done with configuring each thing and
        // go through the configuration steps one at a time.
        // Also, maybe configuration messages should be separate from other messages?
        // Alternatively, we load the openApiDoc the first time we need it in the
        // validate method.
        // But doing this here would allow us to check to make sure the doc really
        // exists before running any of the test
        // And that it's a valid document?

        this.context.readTextFromFile(specMessage.body.path)
          .then(openApiDoc => {
            return yaml.load(openApiDoc.text)
          })
          .then(schema => {
            console.log("Got the contract", schema)
            this.validator = new OpenApiValidator(schema)
          })
          .catch(err => {
            console.log("error", err)
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

  setupStub(stub, uriDescriptor, out, abort) {
    this.server.addHandler(stub.route.method, uriDescriptor, (xhr) => {

      if (this.validator) {
        this.validator.validateRequest(xhr, abort)
      }

      if (stub.error === "network") {
        xhr.setNetworkError()
        this.context.timer.releaseHold()
      } else if (stub.error === "timeout") {
        xhr.setRequestTimeout()
        this.context.timer.releaseHold()
      } else {
        switch (stub.progress.type) {
          case "sent":
            xhr.uploadProgress(stub.progress.transmitted)
            this.context.timer.releaseHold()
            break
          case "received":
            this.responseBodySize(stub.body)
              .then(size => {
                xhr.setResponseHeaders(stub.headers)
                xhr.downloadProgress(stub.progress.transmitted, size)
                this.context.timer.releaseHold()
              })
              .catch(error => this.handleFileLoadError(abort, error))
            break
          case "streamed":
            xhr.setResponseHeaders(stub.headers)
            xhr.downloadProgress(stub.progress.transmitted)
            this.context.timer.releaseHold()
            break
          case "complete":
            this.responseBody(stub.body)
              .then(body => {

                if (this.validator) {
                  this.validator.validateResponse(xhr, stub.status, body, abort)
                }

                xhr.respond(stub.status, stub.headers, body)
                this.context.timer.releaseHold()
              })
              .catch(error => this.handleFileLoadError(abort, error))
            break
        }
      }
    })
  }

  handleFileLoadError(abort, error) {
    switch (error.type) {
      case "file":
        abort(fileError(error.path))
        this.context.timer.releaseHold()
        break
      default:
        abort(missingLoadFileCapabilityError())
        this.context.timer.releaseHold()
    }
  }

  responseBody(body) {
    switch (body.type) {
      case "empty":
        return Promise.resolve(null)
      case "text":
        return Promise.resolve(body.content)
      case "binary":
        return Promise.resolve(Uint8Array.from(body.content).buffer)
      case "bytesFromFile":
        return this.context.readBytesFromFile(body.path)
          .then(({ buffer }) => Uint8Array.from(buffer.data).buffer)
      case "textFromFile":
        return this.context.readTextFromFile(body.path)
          .then(({ text }) => text)
    }
  }

  responseBodySize(body) {
    switch (body.type) {
      case "empty":
        return Promise.resolve(0)
      case "text":
        return Promise.resolve(body.content.length)
      case "binary":
        return Promise.resolve(body.content.length)
      case "bytesFromFile":
        return this.context.readBytesFromFile(body.path)
          .then(({ buffer }) => buffer.data.length)
      case "textFromFile":
        return this.context.readBytesFromFile(body.path)
          .then(({ buffer }) => buffer.data.length)
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

const fileError = (path) => {
  return report(
    line("Unable to read file at", path)
  )
}

const missingLoadFileCapabilityError = () => {
  return report(
    line("An attempt was made to load a file from disk, but this runner does not support that capability."),
    line("If you need to load a file from disk, consider using the standard elm-spec runner.")
  )
}

const buildRequest = (request) => {
  return buildRequestData(request.headers, request.body)
    .then((requestData) => {
      return {
        methpd: request.method,
        url: request.url,
        headers: request.headers,
        body: requestData
      }
    })
}

const buildRequestData = (headers, rawData) => {
  if (!rawData) {
    return Promise.resolve(null)
  }

  if (rawData instanceof File && rawData.name !== "blob") {
    return Promise.resolve({
      type: "file",
      content: rawData
    })
  }

  if (rawData instanceof Blob) {
    return new BlobReader(rawData).readIntoArray()
      .then((data) => {
        return { type: "bytes", mimeType: getMimeType(headers, rawData), data }
      })
  }

  if (rawData instanceof FormData) {
    const promises = []
    for (let key of rawData.keys()) {
      promises.push(buildRequestData(headers, rawData.get(key)).then(body => {
        return { name: key, data: body }
      }))
    }

    return Promise.all(promises).then(parts => {
      return { type: "multipart", parts }
    })
  }

  return Promise.resolve({
    type: "string",
    content: rawData
  })
}

const getMimeType = (headers, blob) => {
  if (blob.type) {
    return blob.type
  }

  return headers['content-type'] || ""
}