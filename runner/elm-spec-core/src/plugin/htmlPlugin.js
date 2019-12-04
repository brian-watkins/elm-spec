const { report, line } = require('../report')
const {
  getLocation,
  setBaseLocation,
  resizeWindowTo,
  setWindowVisibility
} = require('../fakes')

module.exports = class HtmlPlugin {
  constructor(context) {
    this.context = context
    this.window = this.context.window
    this.document = this.window.document
  }

  handle(specMessage, out, next, abort) {
    switch (specMessage.name) {
      case "query": {
        this.renderAndThen(() => {
          const selector = specMessage.body.selector
          const element = this.document.querySelector(selector)
          if (element) {
            out(this.selected(this.describeElement(element)))
          } else {
            out(this.elementNotFound())
          }
        })

        break
      }
      case "queryAll": {
        this.renderAndThen(() => {
          const selector = specMessage.body.selector
          const elements = Array.from(this.document.querySelectorAll(selector)).map(element => this.describeElement(element))
          out(this.selected(elements))
        })

        break
      }
      case "target": {
        this.renderAndThen(() => {
          const element = this.getElement(specMessage.body)
          if (element == null) {
            abort(report(
              line("No match for selector", specMessage.body)
            ))
          } else {
            out(specMessage)
          }
        })

        break
      }
      case "customEvent": {
        this.verifySelector(specMessage.body.name, { props: specMessage.body, forElementsOnly: false }, abort, (props) => {
          const element = this.getElement(props.selector)
          const event = this.getEvent(props.name)
          Object.assign(event, props.event)
          element.dispatchEvent(event)
        })
        break
      }
      case "click": {
        this.verifySelector("click", { props: specMessage.body, forElementsOnly: false }, abort, (props) => {
          const element = this.getElement(props.selector)
          element.dispatchEvent(this.getEvent("mousedown"))
          element.dispatchEvent(this.getEvent("mouseup"))
          if ('click' in element) {
            element.click()
          } else {
            element.dispatchEvent(this.getEvent("click"))
          }
        })
        break
      }
      case "doubleClick": {
        this.verifySelector("doubleClick", { props: specMessage.body, forElementsOnly: true }, abort, (props) => {
          const clickMessage = {
            home: "_html",
            name: "click",
            body: {
              selector: props.selector
            }
          }
          this.handle(clickMessage, out, abort)
          this.handle(clickMessage, out, abort)
          
          const element = this.document.querySelector(props.selector)
          element.dispatchEvent(this.getEvent("dblclick"))
        })
        break
      }
      case "mouseMoveIn": {
        this.verifySelector("mouseMoveIn", { props: specMessage.body, forElementsOnly: true }, abort, (props) => {
          const element = this.document.querySelector(props.selector)
          element.dispatchEvent(this.getEvent("mouseover"))
          element.dispatchEvent(this.getEvent("mouseenter", { bubbles: false }))
        })
        break
      }
      case "mouseMoveOut": {
        this.verifySelector("mouseMoveOut", { props: specMessage.body, forElementsOnly: true }, abort, (props) => {
          const element = this.document.querySelector(props.selector)
          element.dispatchEvent(this.getEvent("mouseout"))
          element.dispatchEvent(this.getEvent("mouseleave", { bubbles: false }))
        })
        break
      }
      case "input": {
        this.verifySelector("input", { props: specMessage.body, forElementsOnly: true }, abort, (props) => {
          const element = this.document.querySelector(props.selector)
          element.value = specMessage.body.text
          const event = this.getEvent("input")
          element.dispatchEvent(event)
        })
        break
      }
      case "focus": {
        this.verifySelector("focus", { props: specMessage.body, forElementsOnly: true }, abort, (props) => {
          const element = this.document.querySelector(props.selector)
          element.focus()
        })
        break
      }
      case "blur": {
        this.verifySelector("blur", { props: specMessage.body, forElementsOnly: true }, abort, (props) => {
          const element = this.document.querySelector(props.selector)
          element.blur()
        })
        break
      }
      case "select": {
        this.verifySelector("select", { props: specMessage.body, forElementsOnly: true }, abort, (props) => {
          const element = this.document.querySelector(props.selector)
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
        resizeWindowTo(size.width, size.height, this.window)
        this.window.dispatchEvent(this.getEvent("resize"))
        break
      }
      case "visibilityChange": {
        setWindowVisibility(specMessage.body.isVisible, this.window)
        this.document.dispatchEvent(this.getEvent("visibilitychange"))
        break
      }
      case "nextAnimationFrame": {
        setTimeout(() => {
          this.renderAndThen(() => {})
        }, 0)
        break
      }
      case "navigation": {
        out({
          home: "navigation",
          name: "current-location",
          body: getLocation(this.window).href
        })
        break
      }
      case "set-location": {
        const location = specMessage.body
        setBaseLocation(location, this.window)
        break
      }
      case "application": {
        this.renderAndThen(() => {
          out({
            home: "application",
            name: "current-title",
            body: this.window.document.title
          })
        })

        break
      }
      default:
        console.log("Unknown message:", specMessage)
        break
    }
  }

  renderAndThen(callback) {
    this.context.clock.runToFrame()
    callback()
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
    return this.window.eval(`new Event('${name}', ${JSON.stringify(details)})`)
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

    handler(props)
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