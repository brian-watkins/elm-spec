
exports.report = (...lines) => {
  return lines
}

exports.line = (statement, detail = null) => {
  return { 
    statement,
    detail
  }
}