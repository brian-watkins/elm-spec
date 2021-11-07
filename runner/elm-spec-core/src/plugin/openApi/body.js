const tryToParse = (message) => {
  let result = message
  try {
    result = JSON.parse(message)
  } catch (err) {}

  return result
}

module.exports = {
  tryToParse
}