function invalid(report) {
  return {
    type: "invalid",
    errorReport: report
  }
}

function valid() {
  return {
    type: "valid"
  }
}

function noMatch() {
  return {
    type: "no-match"
  }
}

module.exports = {
  invalid,
  valid,
  noMatch
}