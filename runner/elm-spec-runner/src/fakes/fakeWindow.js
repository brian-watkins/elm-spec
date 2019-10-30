
exports.fakeWindow = (theWindow, location) => {
  return new Proxy(theWindow, {
    get: (target, prop) => {
      if (prop === 'addEventListener') {
        return customAddEventListener(theWindow, target)
      }
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

const customAddEventListener = (theWindow, target) => (type, handler) => {
  if (type === "resize") {
    target.addEventListener(type, (e) => {
      handler({ target: { innerWidth: theWindow._elm_spec.innerWidth, innerHeight: theWindow._elm_spec.innerHeight }})
    })
  } else {
    target.addEventListener(type, handler)
  }
}