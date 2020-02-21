const { fakeElement } = require('./fakeElement')

exports.fakeDocument = (theWindow, location) => {
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
      if (prop === 'getElementById') {
        return customDocumentElementById(theWindow, target)
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

const customDocumentElementById = (theWindow, target) => (elementId) => {
  const element = target.getElementById(elementId)
  if (!element) return null
  return fakeElement(theWindow, element)
}

const customAddEventListener = (theWindow, target) => (type, handler) => {
  let listener = (type === "visibilitychange")
    ? visibilityChangeListener(theWindow, handler)
    : handler
   
  if (theWindow._elm_spec.documentEventListeners[type] === undefined) {
    theWindow._elm_spec.documentEventListeners[type] = []
  }
  theWindow._elm_spec.documentEventListeners[type].push(listener)
  target.addEventListener(type, listener)
}

const customRemoveEventListener = (theWindow, target) => (type, fun) => {
  if (type === 'visibilitychange') {
    target.removeEventListener(type, theWindow._elm_spec.documentEventListeners['visibilitychange'].pop())
  } else {
    target.removeEventListener(type, fun)
  }
}

const visibilityChangeListener = (theWindow, handler) => (e) => {
  handler({ target: { hidden: !theWindow._elm_spec.isVisible } })
}