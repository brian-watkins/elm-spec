
exports.proxiedConsole = (writeLog) => {
  return new Proxy(console, {
    get: (target, prop) => {
      if (prop === 'warn') {
        return () => {}
      } else if (prop === 'log') {
        return (message) => { writeLog(message) }
      } else {
        return target[prop]
      }
    }
  })
}