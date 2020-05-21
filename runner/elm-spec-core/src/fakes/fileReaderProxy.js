exports.fileReaderProxy = function(timer) {
  return new Proxy(FileReader, {
    construct: (target, args) => {
      timer.requestHold()
      const reader = new target(...args)
      reader.addEventListener('loadend', () => {
        timer.releaseHold()
      })
      return reader
    }
  })
}