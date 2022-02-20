const WebSocketReporter = require('./websocketReporter')

var websocketURL = new URL('/connect', window.location.href);
websocketURL.protocol = "ws:"
const socket = new WebSocket(websocketURL.href)

let specsFinished = false

socket.addEventListener('open', function () {

  socket.addEventListener("message", function (event) {
    handleMessage(socket, JSON.parse(event.data))
  })

  socket.addEventListener("close", function() {
    if (!specsFinished) {
      showSpecsFinished("Connection to elm-spec runner closed.")
    }
  })

  socket.addEventListener("error", function() {
    showSpecsFinished("Lost connection with elm-spec runner!")
  })

});

const handleMessage = (socket, message) => {
  switch (message.action) {
    case "run-specs":
      window._elm_spec_run(message.options, new WebSocketReporter(socket))
        .then((results) => {
          socket.send(JSON.stringify({
            action: "specs-finished",
            results
          }))
        })
      break
    case "reload-specs":
      window.location.reload()
      break
    case "close":
      specsFinished = true
      socket.close()
      showSpecsFinished("Spec suite run complete.")
    
      break
  }
}

const showSpecsFinished = (message) => {
  const el = document.createElement("H1")
  el.id = "specs-finished"
  el.setAttribute("style", "position: absolute; top: 0px; left: 0px; width: 100%; text-align: center; margin: 0px; padding: 30px; background: #CCCCCC")
  el.appendChild(document.createTextNode(message))

  document.body.appendChild(el)
}