const Route = require('route-parser')

module.exports = class OpenApiPath {
  constructor(path, data) {
    this.data = data
    this.path = path
    this.route = new Route(path.replace("{", ":").replace("}", ""))
  }

  operation(request) {
    return this.data[request.method.toLowerCase()]
  }

  match(url) {
    const pathParams = this.route.match(url.pathname)
    return {
      matches: pathParams,
      params: pathParams
    }
  }
}
