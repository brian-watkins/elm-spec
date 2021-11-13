const RequestValidator = require('./requestValidator')
const ResponseValidator = require('./responseValidator')
const OpenAPISchemaValidator = require('openapi-schema-validator').default;
const { report, line } = require('../../report')

const schemaValidators = {
  '2': new OpenAPISchemaValidator({ version: 2 }),
  '3': new OpenAPISchemaValidator({ version: 3 })
}

function getVersion(doc) {
  if (doc.swagger === '2.0') {
    return '2'
  } else if (doc.openapi) {
    return '3'
  } else {
    return null
  }
}

module.exports = class OpenApiContract {
  static validateContract(path, doc) {
    const version = getVersion(doc)

    if (!version) {
      return schemaErrorReport(path, [{ instancePath: '', message: "Unable to determine OpenApi version" }])
    }

    const errors = schemaValidators[version].validate(doc)
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

  validateRequest(request) {
    return this.validate(this.requestValidators, { request })
  }

  validateResponse(request, statusCode, headers, body) {
    return this.validate(this.responseValidators, { request, statusCode, headers, body })
  }

  validate(validators, details) {
    for (const validator of validators) {
      const result = validator.validate(details)
      switch (result.type) {
        case 'valid':
          return null
        case 'invalid':
          return result.errorReport
        case 'no-match':
      }
    }

    return report(
      line("An invalid request was made", `${details.request.method} ${details.request.url}`),
      line("The OpenAPI document contains no path that matches this request.")
    )
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