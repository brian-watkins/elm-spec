
let wrapper = null

const setup = async () => {
  if (!wrapper) {
    wrapper = window._elm_spec.startHarness()
  }
  await wrapper.setup()
}

const observe = async (name, expected) => {
  return await wrapper.observe(name, expected)
}

const runSteps = async (name) => {
  return await wrapper.runSteps(name)
}

const getElmApp = () => {
  return wrapper.app
}

module.exports = {
  getElmApp,
  setup,
  observe,
  runSteps
}