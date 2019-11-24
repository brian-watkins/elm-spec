const nise = require('nise')

const fakeServerForGlobalContext = function(window) {
  const server = nise.fakeServer.create() 
  server.xhr = nise.fakeXhr.fakeXMLHttpRequestFor(window).useFakeXMLHttpRequest()
  server.xhr.onCreate = (xhrObj) => {
    xhrObj.unsafeHeadersEnabled = function () {
        return !(server.unsafeHeadersEnabled === false);
    };
    server.addRequest(xhrObj);
  }
  server.respondImmediately = true
  return server
}

module.exports = class HttpPlugin {
  constructor(context) {
    this.server = fakeServerForGlobalContext(context.window)
  }

  handle(specMessage, out, next, abort) {
    switch (specMessage.name) {
      case "setup": {
        this.server.reset()
        break
      }
      case "stub": {
        const stub = specMessage.body
        this.server.respondWith(stub.method, stub.url, (request) => {
          if (stub.shouldRespond) {
            if (stub.error === "network") {
              request.error()
            } else if (stub.error === "timeout") {
              request.eventListeners.timeout[1].listener()
              request.readyState = 4
            } else {
              request.respond(stub.status, stub.headers, stub.body)
            }
          } else {
            request.readyState = 4
            next()
          }
        })

        break
      }
      case "fetch-requests": {
        const route = specMessage.body

        const requests = this.server.requests
          .filter(request => request.url === route.url && request.method === route.method)
          .map(buildRequest)

        out({
          home: "_http",
          name: "requests",
          body: requests
        })

        break
      }
      default:
        console.log("Unknown Http message", specMessage)
    }
  }
}

const buildRequest = (request) => {
  return {
    url: request.url,
    headers: request.requestHeaders,
    body: request.requestBody
  }
}