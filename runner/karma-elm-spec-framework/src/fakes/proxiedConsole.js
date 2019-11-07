
exports.proxiedConsole = () => {
  return new Proxy(console, {
    get: (target, prop) => {
      if (prop === 'warn') {
        return () => {}
      } else {
        return target[prop]
      }
    }
  })
}