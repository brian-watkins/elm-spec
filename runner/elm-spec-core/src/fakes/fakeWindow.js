
module.exports = class FakeWindow {

  constructor(theWindow, browser, location) {
    this.location = location
    this.browser = browser
    this.eventListeners = {}
    this.proxy = this.createProxy(theWindow)
  }

  clearEventListeners() {
    this.eventListeners = {}
  }

  createProxy(theWindow) {
    return new Proxy(theWindow, {
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
        if (prop === 'scroll') {
          return (x, y) => {
            this.browser.viewportOffset = { x, y }
          }
        }
        if (prop === 'pageXOffset') {
          return this.browser.viewportOffset.x
        }
        if (prop === 'pageYOffset') {
          return this.browser.viewportOffset.y
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

  customAddEventListener(target) {
    return (type, handler) => {
      const listener = (type === "resize")
        ? this.resizeListener(handler)
        : handler

      if (this.eventListeners[type] === undefined) {
        this.eventListeners[type] = []
      }
      this.eventListeners[type].push(listener)

      target.addEventListener(type, listener)
    }
  }

  customRemoveEventListener(target) {
    return (type, fun) => {
      if (type === 'resize') {
        target.removeEventListener(type, this.eventListeners['resize'].pop())
      } else {
        target.removeEventListener(type, fun)
      }
    }
  }

  resizeListener(handler) {
    return (e) => {
      handler({
        target: {
          innerWidth: this.browser.innerWidth,
          innerHeight: this.browser.innerHeight
        }
      })
    }
  }
}