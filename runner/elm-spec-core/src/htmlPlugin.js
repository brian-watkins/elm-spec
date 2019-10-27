
module.exports = class HtmlPlugin {
  constructor(context, window, clock) {
    this.context = context
    this.window = window
    this.document = window.document
    this.clock = clock
  }

  handle(specMessage, out, abort) {
    switch (specMessage.name) {
      case "select": {
        this.clock.runToFrame()
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
        this.clock.runToFrame()
        const selector = specMessage.body.selector
        const elements = Array.from(this.document.querySelectorAll(selector)).map(element => this.describeElement(element))
        out(this.selected(elements))
        break
      }
      case "target": {
        this.clock.runToFrame()
        const element = this.document.querySelector(specMessage.body)
        if (element == null) {
          abort([{
            statement: "No match for selector",
            detail: specMessage.body
          }])
        } else {
          out(specMessage)
        }
        break
      }
      case "customEvent": {
        const props = specMessage.body
        const element = this.document.querySelector(props.selector)
        const event = this.window.eval(`new Event('${props.name}')`)
        Object.assign(event, props.event)
        element.dispatchEvent(event)
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
      case "navigation": {
        out({
          home: "navigation",
          name: "current-location",
          body: this.context.location.href
        })
        break
      }
      case "set-location": {
        const location = specMessage.body
        this.context.setBaseLocation(location)
        break
      }
      case "application": {
        this.clock.runToFrame()
        out({
          home: "application",
          name: "current-title",
          body: this.window.document.title
        })
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
      attributes: this.getAttributes(element),
      children: [
        { text: element.textContent }
      ]
    }
  }

  getAttributes(element) {
    let attributes = {}
    const attrs = element.attributes
    for (let i = 0; i < attrs.length; i++) {
      attributes[attrs[i].name] = attrs[i].value
    }
    return attributes
  }
}