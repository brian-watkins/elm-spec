
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
        const element = this.getElement(specMessage.body)
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
        if (props.selector) {
          const element = this.getElement(props.selector)
          const event = this.getEvent(props.name)
          Object.assign(event, props.event)
          element.dispatchEvent(event)
        } else {
          this.elementNotTargetedForEvent(props.name, abort)
        }
        break
      }
      case "click": {
        const props = specMessage.body
        if (props.selector) {
          const element = this.document.querySelector(specMessage.body.selector)
          element.dispatchEvent(this.getEvent("mousedown"))
          element.dispatchEvent(this.getEvent("mouseup"))
          element.click()
        } else {
          this.elementNotTargetedForEvent("click", abort)
        }
        break
      }
      case "input": {
        const props = specMessage.body
        if (props.selector) {
          const element = this.document.querySelector(specMessage.body.selector)
          element.value = specMessage.body.text
          const event = this.getEvent("input")
          element.dispatchEvent(event)  
        } else {
          this.elementNotTargetedForEvent("input", abort)
        }
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

  elementNotTargetedForEvent(event, abort) {
    abort([{
      statement: "No element targeted for event",
      detail: event
    }])
  }

  getElement(selector) {
    if (selector === "_document_") {
      return this.document
    }

    return this.document.querySelector(selector)
  }

  getEvent(name) {
    return this.window.eval(`new Event('${name}')`)
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