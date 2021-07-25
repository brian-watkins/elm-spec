
function createProxyApp(app) {
  const proxyApp = {
    ports: {}
  }
  
  for (const port in app.ports) {
    if (app.ports[port].hasOwnProperty("subscribe")) {
      proxyApp.ports[port] = {
        subscribe: (subscriber) => {
          proxyApp.ports[port].listener = subscriber
          app.ports[port].subscribe(subscriber)
        },
        unsubscribe: () => {
          if (proxyApp.ports[port].listener !== undefined) {
            app.ports[port].unsubscribe(proxyApp.ports[port].listener)
          }
        }
      }
    } else {
      proxyApp.ports[port] = { send: app.ports[port].send }
    }
  }
  
  proxyApp.resetPorts = () => {
    for (const port in proxyApp.ports) {
      if (proxyApp.ports[port].hasOwnProperty("unsubscribe")) {
        proxyApp.ports[port].unsubscribe()
      }
    }
  }

  return proxyApp
}


module.exports = {
  createProxyApp
}