
let wrapper = null

const setup = async() => {
  // this needs to wait until the app has run the setup ...
  wrapper = window._elm_spec.startHarness()
}

const observe = async (name, expected) => {
  return await wrapper.observe(name, expected)
}

module.exports = {
  setup,
  observe
}