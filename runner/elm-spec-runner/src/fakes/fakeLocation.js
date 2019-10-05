module.exports = class FakeLocation {
  static forOwner(owner, location) {
    return new Proxy(owner, {
      get: (target, prop) => {
        if (prop === 'location') {
          return location
        }
        return target[prop]
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

  constructor(sendToProgram) {
    this.sendToProgram = sendToProgram
    this.href = "http://localhost"
  }

  assign(url) {
    this.href = url
    this.sendToProgram({
      home: '_scenario',
      name: 'state',
      body: 'CONTINUE'
    })
  }

  reload(forceReload) {
    this.sendToProgram({
      home: '_navigation',
      name: 'reload',
      body: null
    })
  }
}