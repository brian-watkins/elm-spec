exports.fakeDate = (clock) => {
  return class FakeDate extends clock.Date {
    constructor () {
      super()

      this.getTimezoneOffset = () => {
        return -1 * FakeDate.fakeTimezoneOffset
      }
    }
  }
}