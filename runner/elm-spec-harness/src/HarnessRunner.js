
let wrapper = window._elm_spec.startHarness()

const setup = async (config) => {
  await wrapper.setup(config)
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