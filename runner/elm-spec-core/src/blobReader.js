module.exports = class BlobReader {
  constructor(blob) {
    this.blob = blob
  }

  readIntoArray() {
    return new Promise((resolve) => {
      const reader = new FileReader()
      reader.addEventListener('loadend', () => {
        const data = new Uint8Array(reader.result)
        resolve(Array.from(data))
      });
      reader.readAsArrayBuffer(this.blob)  
    })
  }
}