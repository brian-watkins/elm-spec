const { match } = require('path-to-regexp')

exports.gatherPathVariables = (route, requestUrlString) => {
  const requestUrl = urlFor(requestUrlString)
  const matched = match(pathString(route))(requestUrl.pathname)

  return Object.assign({}, matched.params)
}

exports.regexForRoute = (route) => {
  return new RegExp(`^${originPattern(route) + pathPattern(route) + queryPattern(route)}$`)
}

const pathString = (route) => {
  return route.path.reduce((pattern, component) => {
    switch (component.type) {
      case "EXACT": {
        return pattern + `/${component.value}`
      }
      case "VARIABLE": {
        return pattern + `/:${component.value}`
      }
    }
  }, "")
}

const urlFor = (urlStr) => {
  let normalizedUrlStr = urlStr
  if (urlStr.startsWith("/")) {
    normalizedUrlStr = "http://localhost" + urlStr
  }

  return new URL(normalizedUrlStr)
}

const originPattern = (route) => {
  switch (route.origin.type) {
    case "ANY": {
      return '[^:#\\?]+:\\/\\/[^\\/#\\?]+'
    }
    case "EXACT": {
      return escape(route.origin.value)
    }
    case "NONE": {
      return ""
    }
  }
}

const pathPattern = (route) => {
  if (route.path.length == 0) {
    return "\\/?"
  }

  return route.path.reduce((acc, component, index) => {
    let pattern
    switch (component.type) {
      case "EXACT": {
        const segmentPattern = escape(component.value)
        if (index === route.path.length - 1) {
          pattern = `\\/(?:${segmentPattern}|${segmentPattern}\\/)`
        } else {
          pattern = `\\/${segmentPattern}`
        }
        break
      }
      case "VARIABLE": {
        if (index === route.path.length - 1) {
          pattern = '\\/[^\\/#\\?]+\\/?'
        } else {
          pattern = '\\/[^\\/#\\?]+'
        }
        break
      }
    }

    return acc + pattern
  }, "")
}

const queryPattern = (route) => {
  switch (route.query.type) {
    case "ANY": {
      return '\\?.*'
    }
    case "EXACT": {
      //need to escape this?
      return '\\?' + route.query.value
    }
    case "NONE": {
      return ""
    }
  }
}

const escape = (part) => {
  return part
    .replace(/(\/|\.)/g, '\\$1')
}