
let wrapper = window._elm_spec.startHarness()

const start = async (name, config) => {
  await wrapper.start(name, config)
}

const stop = () => {
  wrapper.stop()
}

const observe = async (name, expected) => {
  return await wrapper.observe(name, expected)
}

const runSteps = async (name, config) => {
  return await wrapper.runSteps(name, config)
}

const getElmApp = () => {
  return wrapper.app
}

module.exports = {
  getElmApp,
  start,
  stop,
  observe,
  runSteps
}