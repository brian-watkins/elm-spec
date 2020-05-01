exports.fakeMouseEvent = () => {
  return new Proxy(MouseEvent, {
    construct: (target, args) => {
      return new target(args[0], { cancelable: true })
    }
  })
}