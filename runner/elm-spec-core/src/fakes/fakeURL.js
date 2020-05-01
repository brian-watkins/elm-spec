
module.exports = class FakeURL {
  constructor(blobStore) {
    this.blobStore = blobStore
    this.keyBase = 0
  }

  createObjectURL(blob) {
    const key = `blob_${this.keyBase++}`

    this.blobStore.put(key, blob)

    return `blob://elm-spec/${key}`
  }

  revokeObjectURL(url) {
    this.blobStore.remove(url.split("/").pop())
  }
}