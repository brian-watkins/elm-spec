
module.exports = class HtmlPlugin {
  constructor(window, clock) {
    this.window = window
    this.document = window.document
    this.clock = clock
  }

  handle(specMessage, out, abort) {
    switch (specMessage.name) {
      case "select": {
        const selector = specMessage.body.selector
        const element = this.document.querySelector(selector)
        if (element) {
          out(this.selected(this.describeElement(element)))
        } else {
          out(this.elementNotFound())
        }
        break
      }
      case "selectAll": {
        const selector = specMessage.body.selector
        const elements = Array.from(this.document.querySelectorAll(selector)).map(this.describeElement)
        out(this.selected(elements))
        break
      }
      case "target": {
        const element = this.document.querySelector(specMessage.body)
        if (element == null) {
          abort(`No match for selector: ${specMessage.body}`)
        } else {
          out(specMessage)
        }
        break
      }
      case "click": {
        const element = this.document.querySelector(specMessage.body.selector)
        element.click()
        break
      }
      case "input": {
        const element = this.document.querySelector(specMessage.body.selector)
        element.value = specMessage.body.text
        const event = this.window.eval("new Event('input', {bubbles: true, cancelable: true})")
        element.dispatchEvent(event)
        break
      }
      default:
        console.log("Unknown message:", specMessage)
        break
    }
  }

  selected(body) {
    return {
      home: "_html",
      name: "selected",
      body: body
    }
  }

  elementNotFound() {
    return {
      home: "_html",
      name: "selected",
      body: null
    }
  }

  describeElement(element) {
    return {
      tag: element.tagName,
      children: [
        { text: element.textContent }
      ]
    }
  }

  onStepComplete() {
    this.clock.runToFrame()
  }
}