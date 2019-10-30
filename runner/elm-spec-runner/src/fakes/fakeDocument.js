
exports.fakeDocument = (theWindow, location) => {
  return new Proxy(theWindow.document, {
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
  if (type === "visibilitychange") {
    target.addEventListener(type, (e) => {
      handler({ target: { hidden: !theWindow._elm_spec.isVisible } })
    })
  } else {
    target.addEventListener(type, handler)
  }
}