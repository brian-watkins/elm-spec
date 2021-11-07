const OpenApiResponseValidator = require('openapi-response-validator').default
const Ajv = require("ajv")
const OpenApiPath = require('./path')
const { tryToParse } = require('./body')
const { report, line } = require('../../report')

const ajv = new Ajv()

module.exports = class ResponseValidator {
  constructor (path, pathData, definitions, components) {
    this.openApiPath = new OpenApiPath(path, pathData)
    this.definitions = definitions
    this.components = components
  }

  validate({ request, statusCode, headers, body }) {
    const url = new URL(request.url)
    console.log("Validating response", url.pathname)
    const path = this.openApiPath.match(url)
    if (path.matches) {
      console.log("Found a matching openapi route")
      const responses = this.responses(request)

      let errors = []

      const responseBodyErrors = new OpenApiResponseValidator({
        responses,
        definitions: this.definitions,
        components: this.components
      })
      .validateResponse(statusCode, tryToParse(body))

      if (responseBodyErrors) {
        errors = errors.concat(responseBodyErrors.errors)
      }

      const headerErrors = this.validateHeaders(request, statusCode, headers)

      if (headerErrors) {
        errors = errors.concat(headerErrors)
      }

      console.log("Validation errors:", errors)
      if (errors.length > 0) {
        return errorReport(request, errors)
      }
    }
    return null
  }

  responses(request) {
    return this.openApiPath.operation(request).responses
  }

  headerSchema(request, statusCode) {
    const response = this.openApiPath.operation(request).responses[statusCode]
    let headers = {}
    if (response) {
      headers = response.headers || {}
      for (const name in headers) {
        if (headers[name].schema) {
          headers[name] = headers[name].schema
        }
      }
    }
    return {
      type: "object",
      properties: headers,
    }
  }

  validateHeaders(request, statusCode, headers) {
    const headerSchema = this.headerSchema(request, statusCode)
    console.log("Header Schema", headerSchema)
    console.log("Response headers", headers)

    const validate = ajv.compile(headerSchema)
    const valid = validate(headers)

    if (!valid) {
      return validate.errors.map(toOpenApiHeaderError)
    }

    return null
  }
}

const toOpenApiHeaderError = (ajvError) => {
  return {
    location: "headers",
    path: ajvError.instancePath.substring(1),
    message: ajvError.message
  }
}

const errorReport = (request, errors) => {
  let lines = [ line("An invalid response was returned for", `${request.method} ${request.url}`) ]

  for (const error of errors) {
    switch (error.location) {
      case 'headers':
        lines = lines.concat([
          line("Problem with header", `${error.path} ${error.message}`)
        ])
        break
      default:
        if (error.path) {
          lines = lines.concat([
            line("Problem with body", `${error.path} ${error.message}`)
          ])  
        } else {
          lines = lines.concat([
            line(error.message)
          ])
        }
    }
  }

  return report(...lines)
}
