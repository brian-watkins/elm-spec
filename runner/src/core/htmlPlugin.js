
module.exports = class HtmlPlugin {
  constructor(document, clock) {
    this.document = document
    this.clock = clock
  }

  handle(specMessage, out) {
    switch (specMessage.name) {
      case "select":
        const selector = specMessage.body.selector
        const element = this.document.querySelector(selector)
        out({
          home: "_html",
          name: "selected",
          body: {
            tag: element.tagName,
            children: [
              { text: element.textContent }
            ]
          }
        })
        break
      case "target":
        out(specMessage)
        break
      case "click":
        const el = this.document.querySelector(specMessage.body.selector)
        el.click()
        this.clock.tick(16)
        break
      default:
        console.log("Unknown message:", specMessage)
        break
    }
  }

  reset() {
  }
}