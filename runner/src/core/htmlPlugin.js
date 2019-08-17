
module.exports = class HtmlPlugin {
  constructor(document) {
    this.document = document
  }

  handle(specMessage, out) {
    switch (specMessage.name) {
      case "select":
        const selector = specMessage.body.selector
        const element = this.document.querySelector(`#${selector}`)
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
    }
  }

  reset() {
  }
}