module.exports = class FakeBrowser {
  constructor() {
    this.innerWidth = 0
    this.innerHeight = 0
    this.viewportOffset = { x: 0, y: 0 }
    this.isVisible = true
  }
}