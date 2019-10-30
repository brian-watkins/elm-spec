
exports.fakeDocument = (theDocument, location) => {
  return new Proxy(theDocument, {
    get: (target, prop) => {
      if (prop === 'location') {
        return location
      }
      return target[prop]
    },
    set: (target, prop, value) => {
      if (prop === 'location') {
        location.assign(value)
      } else {
        target[prop] = value
      }
      return true
    }
  })
}