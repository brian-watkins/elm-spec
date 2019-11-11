module.exports = class FakeHistory {
  constructor(location) {
    this.location = location
  }

  pushState(state, title, url) {
    const updated = new URL(url, this.location.href)
    this.location.href = updated.href
  }

  replaceState(state, title, url) {
    const updated = new URL(url, this.location.href)
    this.location.href = updated.href
  }
}