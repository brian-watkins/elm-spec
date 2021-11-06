const Route = require('route-parser')
const queryString = require('query-string');
const OpenAPIRequestValidator = require('openapi-request-validator').default
const OpenapiRequestCoercer = require('openapi-request-coercer').default
const OpenApiResponseValidator = require('openapi-response-validator').default
const { report, line } = require('../report')

module.exports = class OpenApiValidator {
  constructor(schema) {
    this.requestValidators = Object.keys(schema.paths).map(path => {
      return new RequestValidator(path, schema.paths[path], schema.definitions, schema.components)
    })
    this.responseValidators = Object.keys(schema.paths).map(path => {
      return new ResponseValidator(path, schema.paths[path], schema.definitions, schema.components)
    })
  }

  validateRequest(request, abort) {
    this.validate(this.requestValidators, { request }, abort)
  }

  validateResponse(request, statusCode, body, abort) {
    this.validate(this.responseValidators, { request, statusCode, body }, abort)
  }

  validate(validators, details, abort) {
    for (const validator of validators) {
      const validationError = validator.validate(details)
      if (validationError) {
        abort(validationError)
      }
    }
  }
}

class RequestValidator {
  constructor (path, pathData, definitions, components) {
    this.openApiPath = new OpenApiPath(path, pathData)
    this.definitions = definitions
    this.components = components
  }

  validate({ request }) {
    const url = new URL(request.url)
    console.log("Validating request", url.pathname)
    const path = this.openApiPath.match(url)
    if (path.matches) {
      console.log("Found a matching openapi route with params", path.params)
      const parameters = this.parameters(request)
      const typedRequest = this.typedRequest(parameters, url, path.params, request)

      const errors = new OpenAPIRequestValidator({
        parameters,
        requestBody: this.requestBody(request),
        schemas: this.schemas()
      })
      .validateRequest({
        headers: typedRequest.headers,
        params: typedRequest.pathParams,
        query: typedRequest.query,
        body: typedRequest.body
      })
      
      console.log("Validation errors:", errors)
      if (errors) {
        return reportRequestValidationError(request, errors.errors)
      }
    }
    return null
  }

  schemas() {
    if (this.components) {
      return this.components.schemas
    }
    return this.definitions
  }

  pathParameters() {
    return this.openApiPath.data.parameters || []
  }

  methodParameters(request) {
    return this.openApiPath.operation(request).parameters || []
  }

  parameters(request) {
    return this.pathParameters().concat(this.methodParameters(request))
  }

  requestBody(request) {
    return this.openApiPath.operation(request).requestBody
  }

  typedRequest(parameters, url, pathParams, request) {
    const query = queryString.parse(url.search)
    const headers = request.requestHeaders.getHash()

    new OpenapiRequestCoercer({ parameters })
      .coerce({
        params: pathParams,
        headers,
        query
      })

    console.log("Typed params", pathParams)
    console.log("Types query", query)
    console.log("Typed Headers", headers)

    return {
      pathParams,
      headers,
      query,
      body: tryToParse(request.body)
    }
  }
}

class ResponseValidator {
  constructor (path, pathData, definitions, components) {
    this.openApiPath = new OpenApiPath(path, pathData)
    this.definitions = definitions
    this.components = components
  }

  validate({ request, statusCode, body }) {
    const url = new URL(request.url)
    console.log("Validating request", url.pathname)
    const path = this.openApiPath.match(url)
    if (path.matches) {
      console.log("Found a matching openapi route")
      const responses = this.responses(request)

      const errors = new OpenApiResponseValidator({
        responses,
        definitions: this.definitions,
        components: this.components
      })
      .validateResponse(statusCode, tryToParse(body))

      console.log("Validation errors:", errors)
      if (errors) {
        return reportResponseValidationError(request, errors.errors)
      }
    }
    return null
  }

  responses(request) {
    return this.openApiPath.operation(request).responses
  }
}

class OpenApiPath {
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

const tryToParse = (message) => {
  let result = message
  try {
    result = JSON.parse(message)
  } catch (err) {}

  return result
}

const reportRequestValidationError = (request, errors) => {
  let lines = [ line("An invalid request was made", `${request.method} ${request.url}`) ]

  for (const error of errors) {
    let message = `${error.path} ${error.message}`
    if (error.errorCode === "required.openapi.requestValidation") {
      message = error.message
    }
    
    switch (error.location) {
      case 'path':
        lines = lines.concat([
          line("Problem with path parameter", message)
        ])
        break
      case 'headers':
        lines = lines.concat([
          line("Problem with headers", message)
        ])
        break
      case 'query':
        lines = lines.concat([
          line("Problem with query", message)
        ])
        break
      case 'body':
        lines = lines.concat([
          line("Problem with body", message)
        ])
        break
    }
  }

  return report(...lines)
}

const reportResponseValidationError = (request, errors) => {
  let lines = [ line("An invalid response was returned for", `${request.method} ${request.url}`) ]

  for (const error of errors) {
    lines = lines.concat([
      line("Problem with body", `${error.path} ${error.message}`)
    ])
  }

  return lines
}
