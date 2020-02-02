
exports.fakeWindow = (theWindow, location) => {
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
  const listener = (type === "resize")
    ? resizeListener(theWindow, handler)
    : handler
  
  if (theWindow._elm_spec.windowEventListeners[type] === undefined) {
    theWindow._elm_spec.windowEventListeners[type] = []
  }
  theWindow._elm_spec.windowEventListeners[type].push(listener)

  target.addEventListener(type, listener)
}

const customRemoveEventListener = (theWindow, target) => (type, fun) => {
  if (type === 'resize') {
    target.removeEventListener(type, theWindow._elm_spec.windowEventListeners['resize'].pop())
  } else {
    target.removeEventListener(type, fun)
  }
}

const resizeListener = (theWindow, handler) => (e) => {
  handler({ target: { innerWidth: theWindow._elm_spec.innerWidth, innerHeight: theWindow._elm_spec.innerHeight }})
}