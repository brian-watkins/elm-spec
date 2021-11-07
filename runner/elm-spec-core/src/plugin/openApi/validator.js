const RequestValidator = require('./requestValidator')
const ResponseValidator = require('./responseValidator')
const { report, line } = require('../../report')

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
