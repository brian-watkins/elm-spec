const RequestValidator = require('./requestValidator')
const ResponseValidator = require('./responseValidator')

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
      const validationError = validator.validate(details)
      if (validationError) {
        abort(validationError)
      }
    }
  }
}
