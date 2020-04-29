module.exports = class BlobStore {
  constructor() {
    this.blobs = {}
  }
  
  get(name) {
    return this.blobs[name]
  }
  
  put(name, blob) {
    this.blobs[name] = blob
  }

  remove(name) {
    delete this.blobs[name]
  }
}