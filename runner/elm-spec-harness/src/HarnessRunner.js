
let wrapper = null

const setup = async() => {
  // this needs to wait until the app has run the setup ...
  if (!wrapper) {
    wrapper = window._elm_spec.startHarness()
  }
}

const observe = async (name, expected) => {
  return await wrapper.observe(name, expected)
}

const runSteps = async (name) => {
  return await wrapper.runSteps(name)
}

module.exports = {
  setup,
  observe,
  runSteps
}