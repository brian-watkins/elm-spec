
module.exports = class HarnessRunner {

  // we might need to provide a path to the harness to compile and run
  async setup() {
    // this needs to wait until the app has run the setup ...
    this.wrapper = window._elm_spec.startHarness()
  }

  async observe(name, expected) {
    return await this.wrapper.observe(name, expected)
  }
}