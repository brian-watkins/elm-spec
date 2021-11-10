const RequestValidator = require('./requestValidator')
const ResponseValidator = require('./responseValidator')
const OpenAPISchemaValidator = require('openapi-schema-validator').default;
const { report, line } = require('../../report')

const schemaValidators = {
  '2': new OpenAPISchemaValidator({ version: 2 }),
  '3': new OpenAPISchemaValidator({ version: 3 })
}

module.exports = class OpenApiValidator {
  static validateSchema(path, schema, version) {
    const errors = schemaValidators[version].validate(schema)
    if (errors.errors.length > 0) {
      return schemaErrorReport(path, errors.errors)
    }

    return null
  }

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

  validateResponse(request, statusCode, headers, body, abort) {
    this.validate(this.responseValidators, { request, statusCode, headers, body }, abort)
  }

  validate(validators, details, abort) {
    for (const validator of validators) {
      const result = validator.validate(details)
      switch (result.type) {
        case 'valid':
          return
        case 'invalid':
          abort(result.errorReport)
          return
        case 'no-match':
      }
    }

    abort(report(
      line("An invalid request was made", `${details.request.method} ${details.request.url}`),
      line("The OpenAPI document contains no path that matches this request.")
    ))
  }
}

const schemaErrorReport = (path, errors) => {
  let lines = [ line("Invalid OpenApi document", path) ]

  for (const error of errors) {
    let message = `${error.instancePath} ${error.message}`
    lines.push(line(message.trim()))
  }

  return report(...lines)
}