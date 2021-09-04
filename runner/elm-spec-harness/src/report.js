
function writeReport(report) {
  return report.map((line) => writeLine(line)).join(" - ")
}

function writeLine(line) {
  if (line.detail) {
    return line.statement + ` '${line.detail}'`
  }

  return line.statement
}

module.exports = {
  writeReport
}