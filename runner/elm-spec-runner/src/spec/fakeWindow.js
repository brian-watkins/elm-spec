class FakeWindow {
  constructor() {
    this._location = "http://localhost/"
  }

  addEventListener() {}

  removeEventListener() {}

  get location() {
    return this._location
  }
  
  set location(val) {
    this._location = val;
    const event = new Event('beforeunload', {returnValue: '', bubbles: true, cancelable: true})
    document.dispatchEvent(event)
  }
}