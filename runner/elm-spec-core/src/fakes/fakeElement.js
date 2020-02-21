
exports.fakeElement = (theWindow, element) => {
  return new Proxy(element, {
    get: (target, prop) => {
      if (prop === 'getBoundingClientRect') {
        return customGetBoundingClientRect(theWindow, target)
      }
      const val = target[prop]
      return typeof val === "function"
        ? (...args) => val.apply(target, args)
        : val;
    },
  })
}

const customGetBoundingClientRect = (theWindow, target) => () => {
  const rect = target.getBoundingClientRect()
  if (typeof DOMRect === "undefined") return rect

  const fakeRect = DOMRect.fromRect(rect)
  fakeRect.x = rect.x - theWindow._elm_spec.viewportOffset.x
  fakeRect.y = rect.y - theWindow._elm_spec.viewportOffset.y
  return fakeRect
}