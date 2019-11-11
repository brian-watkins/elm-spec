module.exports = class FakeLocation {
  constructor(sendToProgram) {
    this.sendToProgram = sendToProgram
    this.href = "http://localhost"
  }

  setBase(document, url) {
    const updated = new URL(url, this.href)
    this.href = updated.href
    const base = document.querySelector("base")
    base.href = updated.protocol + "//" + updated.host
  }

  assign(url) {
    const updated = new URL(url, this.href)
    this.href = updated.href
    this.sendToProgram({
      home: '_navigation',
      name: 'assign',
      body: url
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