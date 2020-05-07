exports.fileReaderProxy = function(cancelTimer) {
  return new Proxy(FileReader, {
    construct: (target, args) => {
      cancelTimer()
      return new target(...args)
    }
  })
}