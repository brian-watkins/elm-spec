
exports.fakeElement = (browser, element) => {
  return new Proxy(element, {
    get: (target, prop) => {
      if (prop === 'getBoundingClientRect') {
        return customGetBoundingClientRect(browser, target)
      }
      const val = target[prop]
      return typeof val === "function"
        ? (...args) => val.apply(target, args)
        : val;
    },
  })
}

const customGetBoundingClientRect = (browser, target) => () => {
  const rect = target.getBoundingClientRect()
  if (typeof DOMRect === "undefined") return rect

  const fakeRect = DOMRect.fromRect(rect)
  fakeRect.x = rect.x - browser.viewportOffset.x
  fakeRect.y = rect.y - browser.viewportOffset.y
  return fakeRect
}