const { report, line } = require('../report')

module.exports = class HtmlPlugin {
  constructor(context) {
    this.context = context
    this.window = this.context.window
  }

  get document() {
    return this.window.document
  }

  handle(specMessage, out, next, abort) {
    switch (specMessage.name) {
      case "query-window": {
        out(this.selected(this.context.fakes.window.proxy))
        break;
      }
      case "query": {
        const selector = specMessage.body.selector
        const element = this.document.querySelector(selector)

        if (element) {
          out(this.selected(element))
        } else {
          out(this.elementNotFound())
        }

        break
      }
      case "queryAll": {
        const selector = specMessage.body.selector
        const elements = Array.from(this.document.querySelectorAll(selector))
        out(this.selected(elements))

        break
      }
      case "target": {
        const element = this.getElement(specMessage.body)
        if (element == null) {
          abort(report(
            line("No match for selector", specMessage.body)
          ))
        } else {
          out(specMessage)
        }

        break
      }
      case "customEvent": {
        this.verifySelector(specMessage.body.name, { props: specMessage.body, forElementsOnly: false }, abort, (props, element) => {
          const event = this.getEvent(props.name)

          for (let customProperty in props.event) {
            Object.defineProperty(event, customProperty, { value: props.event[customProperty] })
          }

          element.dispatchEvent(event)
        })
        break
      }
      case "click": {
        this.verifySelector("click", { props: specMessage.body, forElementsOnly: false }, abort, (props, element) => {
          this.dispatchClick(element)
        })
        break
      }
      case "doubleClick": {
        this.verifySelector("doubleClick", { props: specMessage.body, forElementsOnly: false }, abort, (props, element) => {
          this.dispatchClick(element)
          this.dispatchClick(element)
          element.dispatchEvent(this.getEvent("dblclick"))
        })
        break
      }
      case "mouseMoveIn": {
        this.verifySelector("mouseMoveIn", { props: specMessage.body, forElementsOnly: true }, abort, (props, element) => {
          element.dispatchEvent(this.getEvent("mouseover"))
          element.dispatchEvent(this.getEvent("mouseenter", { bubbles: false }))
        })
        break
      }
      case "mouseMoveOut": {
        this.verifySelector("mouseMoveOut", { props: specMessage.body, forElementsOnly: true }, abort, (props, element) => {
          element.dispatchEvent(this.getEvent("mouseout"))
          element.dispatchEvent(this.getEvent("mouseleave", { bubbles: false }))
        })
        break
      }
      case "input": {
        this.verifySelector("input", { props: specMessage.body, forElementsOnly: true }, abort, (props, element) => {
          element.value = specMessage.body.text
          const event = this.getEvent("input")
          element.dispatchEvent(event)
        })
        break
      }
      case "focus": {
        this.verifySelector("focus", { props: specMessage.body, forElementsOnly: true }, abort, (props, element) => {
          element.focus()
        })
        break
      }
      case "blur": {
        this.verifySelector("blur", { props: specMessage.body, forElementsOnly: true }, abort, (props, element) => {
          element.blur()
        })
        break
      }
      case "select": {
        this.verifySelector("select", { props: specMessage.body, forElementsOnly: true }, abort, (props, element) => {
          const options = element.querySelectorAll("option")
          for (let i = 0; i < options.length; i++) {
            const option = options.item(i)
            if (option.label === props.text) {
              option.selected = true
              element.dispatchEvent(this.getEvent("change"))
              element.dispatchEvent(this.getEvent("input"))
              break
            }
          }
        })
        break
      }
      case "resize": {
        const size = specMessage.body
        this.context.resizeWindowTo(size.width, size.height)
        this.window.dispatchEvent(this.getEvent("resize"))
        break
      }
      case "visibilityChange": {
        this.context.setWindowVisibility(specMessage.body.isVisible)
        this.document.dispatchEvent(this.getEvent("visibilitychange"))
        break
      }
      case "set-location": {
        const location = specMessage.body
        this.context.setBaseLocation(location)
        break
      }
      case "set-browser-viewport": {
        this.context.setBrowserViewport(specMessage.body)
        break
      }
      case "set-element-viewport": {
        this.verifySelector("setElementViewport", { props: specMessage.body, forElementsOnly: true }, abort, (props, element) => {
          const viewport = props.viewport
          element.scrollLeft = viewport.x
          element.scrollTop = viewport.y
        })

        break
      }
      default:
        console.log("Unknown message:", specMessage)
        break
    }
  }

  dispatchClick(element) {
    element.dispatchEvent(new MouseEvent("mousedown", { bubbles: true, cancelable: true }))
    element.dispatchEvent(new MouseEvent("mouseup", { bubbles: true, cancelable: true }))
    element.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }))
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
    abort(report(
      line("No element targeted for event", event)
    ))
  }

  getElement(selector) {
    if (selector === "_document_") {
      return this.document
    }

    return this.document.querySelector(selector)
  }

  getEvent(name, options = {}) {
    const details = Object.assign({ bubbles: true, cancelable: true }, options)
    return new Event(name, details)
  }

  verifySelector(name, { props, forElementsOnly }, abort, handler) {
    if (!props.selector) {
      this.elementNotTargetedForEvent(name, abort)
      return
    }

    if (forElementsOnly && props.selector === "_document_") {
      abort(report(
        line("Event not supported when document is targeted", name)
      ))
      return
    }

    const element = this.getElement(props.selector)

    if (props.selector !== "_document_" && element == null) {
      abort(report(
        line("No match for selector", props.selector)
      ))
      return
    }

    handler(props, element)
  }
}