const { fakeElement } = require('./fakeElement')

exports.fakeDocument = (theWindow, location, openFileSelector, recordDownload, blobStore) => {
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
      if (prop === 'createElement') {
        return customCreateElement(target, openFileSelector, recordDownload, blobStore)
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

const customCreateElement = (target, openFileSelector, recordDownload, blobStore) => (tagName, options) => {
  const element = target.createElement(tagName, options)
  if (tagName !== "input" && tagName !== "a") {
    return element
  }

  const originalDispatch = element.dispatchEvent.bind(element)
  return Object.defineProperty(element, "dispatchEvent", {
    value: (event) => {
      if (element.tagName === "INPUT" && element.type === "file" && event.type === "click") {
        openFileSelector(element)
      }
      if (element.tagName === "A" && element.attributes.getNamedItem("download") && event.type === "click") {
        const downloadUrl = new URL(element.href)

        if (downloadUrl.protocol === "blob:") {
          var reader = new FileReader();
          reader.addEventListener('loadend', function() {
            recordDownload(element.download, { type: "text", text: reader.result })
          });
          const blobKey = downloadUrl.pathname.split("/").pop()
          reader.readAsText(blobStore.get(blobKey));
        } else {
          const filename = element.download === "" ? downloadUrl.pathname.substr(1) : element.download
          recordDownload(filename, { type: "fromUrl", url: element.href })
        }

        event = new Event("click", { bubbles: true, cancelable: true })
        event.preventDefault()
      }
      return originalDispatch(event)
    }
  })
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