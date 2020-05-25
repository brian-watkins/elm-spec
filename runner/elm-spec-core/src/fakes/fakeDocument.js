const { fakeElement } = require('./fakeElement')

module.exports = class FakeDocument {
  constructor(theWindow, fakeLocation) {
    this.window = theWindow
    this.location = fakeLocation
    this.elementMappers = []
    this.proxy = this.createProxy()
  }

  addElementMapper(mapper) {
    this.elementMappers.push(mapper)
  }

  clearElementMappers() {
    this.elementMappers = []
  }

  createProxy() {
    return new Proxy(this.window.document, {
      get: (target, prop) => {
        if (prop === 'addEventListener') {
          return this.customAddEventListener(target)
        }
        if (prop === 'removeEventListener') {
          return this.customRemoveEventListener(target)
        }
        if (prop === 'location') {
          return this.location
        }
        if (prop === 'getElementById') {
          return this.customElementById(target)
        }
        if (prop === 'createElement') {
          return this.customCreateElement(target)
        }
        if (prop === 'documentElement') {
          return this.customDocumentElement(target.documentElement)
        }
        const val = target[prop]
        return typeof val === "function"
          ? (...args) => val.apply(target, args)
          : val;
      },
      set: (target, prop, value) => {
        if (prop === 'location') {
          this.location.assign(value)
        } else {
          target[prop] = value
        }
        return true
      }
    })
  }

  customCreateElement(target) {
    return (tagName, options) => {
      const element = target.createElement(tagName, options)
      return this.elementMappers.reduce((el, mapper) => mapper(el), element)
    }
  }

  customElementById(target) {
    return (elementId) => {
      const element = target.getElementById(elementId)
      if (!element) return null
      return fakeElement(this.window, element)
    }
  }

  customDocumentElement(documentElement) {
    return new Proxy(documentElement, {
      get: (target, prop) => {
        if (prop === 'clientWidth') {
          return this.window._elm_spec.innerWidth
        }
        if (prop === 'clientHeight') {
          return this.window._elm_spec.innerHeight
        }
        const val = target[prop]
        return typeof val === "function"
          ? (...args) => val.apply(target, args)
          : val;
      }
    })
  }

  customAddEventListener(target)  {
    return (type, handler) => {
      let listener = (type === "visibilitychange")
        ? this.visibilityChangeListener(handler)
        : handler
      
      if (this.window._elm_spec.documentEventListeners[type] === undefined) {
        this.window._elm_spec.documentEventListeners[type] = []
      }
      this.window._elm_spec.documentEventListeners[type].push(listener)
      target.addEventListener(type, listener)
    }
  }  

  customRemoveEventListener(target)  {
    return (type, fun) => {
      if (type === 'visibilitychange') {
        target.removeEventListener(type, this.window._elm_spec.documentEventListeners['visibilitychange'].pop())
      } else {
        target.removeEventListener(type, fun)
      }
    }
  }
  
  visibilityChangeListener(handler) {
    return (e) => {
      handler({ target: { hidden: !this.window._elm_spec.isVisible } })
    }
  }
}