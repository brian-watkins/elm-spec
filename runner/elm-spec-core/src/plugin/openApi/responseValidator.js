const OpenApiResponseValidator = require('openapi-response-validator').default
const OpenapiRequestCoercer = require('openapi-request-coercer').default
const Ajv = require("ajv")
const OpenApiPath = require('./path')
const { tryToParse } = require('./body')
const { report, line } = require('../../report')
const { valid, invalid, noMatch } = require('./validationResult')

const ajv = new Ajv({ allErrors: true })

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
        return invalid(errorReport(request, errors))
      } else {
        return valid()
      }
    }

    return noMatch()
  }

  responses(request) {
    return this.openApiPath.operation(request).responses
  }

  headerSchema(request, statusCode) {
    const response = this.openApiPath.operation(request).responses[statusCode]
    let headers = {}
    if (response) {
      let responseHeaders = response.headers || {}
      for (const name in responseHeaders) {
        if (responseHeaders[name].schema) {
          headers[name.toLowerCase()] = responseHeaders[name].schema
        } else {
          headers[name.toLowerCase()] = responseHeaders[name]
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
    const typedHeaders = this.typedHeaders(headerSchema, headers)
    console.log("Response headers", typedHeaders)

    const validate = ajv.compile(headerSchema)
    const valid = validate(typedHeaders)

    if (!valid) {
      return validate.errors.map(toOpenApiHeaderError)
    }

    return null
  }

  typedHeaders(schema, headers) {
    const parameters = Object.keys(schema.properties).map((headerName) => {
      return {
        in: 'header',
        name: headerName,
        ...schema.properties[headerName],
      }
    })

    console.log("Parameters for typing headers", parameters)

    let normalizedHeaders = {}
    for (const name in headers) {
      normalizedHeaders[name.toLowerCase()] = headers[name]
    }

    new OpenapiRequestCoercer({ parameters })
      .coerce({
        headers: normalizedHeaders
      })

    return normalizedHeaders
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
          line("Problem with headers", `${error.path} ${error.message}`)
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
