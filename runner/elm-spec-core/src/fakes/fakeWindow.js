
exports.fakeWindow = (theWindow, location) => {
  theWindow._elm_spec.resizeListeners = []
  const viewport = {
    x: 0,
    y: 0,
  }

  return new Proxy(theWindow, {
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
      if (prop === 'scroll') {
        return (x, y) => {
          viewport.x = x
          viewport.y = y
        }
      }
      if (prop === 'pageXOffset') {
        return viewport.x
      }
      if (prop === 'pageYOffset') {
        return viewport.y
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
  if (type === "resize") {
    const listener = resizeListener(theWindow, handler)
    theWindow._elm_spec.resizeListeners.push(listener)
    target.addEventListener(type, listener)
  } else {
    target.addEventListener(type, handler)
  }
}

const customRemoveEventListener = (theWindow, target) => (type, fun) => {
  if (type === 'resize') {
    target.removeEventListener(type, theWindow._elm_spec.resizeListeners.pop())
  } else {
    target.removeEventListener(type, fun)
  }
}

const resizeListener = (theWindow, handler) => (e) => {
  handler({ target: { innerWidth: theWindow._elm_spec.innerWidth, innerHeight: theWindow._elm_spec.innerHeight }})
}