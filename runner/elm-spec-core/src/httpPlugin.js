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
  return server
}

module.exports = class HttpPlugin {
  constructor(window) {
    this.server = fakeServerForGlobalContext(window)
    this.server.respondImmediately = true
  }

  handle(specMessage, out, abort) {
    switch (specMessage.name) {
      case "stub": {
        const stub = specMessage.body
        this.server.respondWith(stub.method, stub.url, [ stub.status, {}, stub.body ])
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
    headers: request.requestHeaders
  }
}