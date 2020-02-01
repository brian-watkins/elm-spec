
exports.fakeDocument = (theWindow, location) => {
  theWindow._elm_spec.visibilityChangeListeners = []

  return new Proxy(theWindow.document, {
    get: (target, prop) => {
      if (prop === 'addEventListener') {
        return customAddEventListener(theWindow, target)
      }
      if (prop === 'removeEventListener') {
        return customRemoveEventListener(theWindow, target)
      }
      if (prop === 'location') {
        return location
      }
      const val = target[prop]
      return typeof val === "function"
        ? (...args) => val.apply(target, args)
        : val;
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
    const listener = visibilityChangeListener(theWindow, handler)
    theWindow._elm_spec.visibilityChangeListeners.push(listener)
    target.addEventListener(type, listener)
  } else {
    target.addEventListener(type, handler)
  }
}

const customRemoveEventListener = (theWindow, target) => (type, fun) => {
  if (type === 'visibilitychange') {
    target.removeEventListener(type, theWindow._elm_spec.visibilityChangeListeners.pop())
  } else {
    target.removeEventListener(type, fun)
  }
}

const visibilityChangeListener = (theWindow, handler) => (e) => {
  handler({ target: { hidden: !theWindow._elm_spec.isVisible } })
}