const { ElmContext, SuiteRunner } = require('elm-spec-core')

const elmContext = new ElmContext(window)

window._elm_spec_run = (options, reporter) => {
  return new Promise((resolve) => {
    new SuiteRunner(elmContext, reporter, options)
      .on('complete', resolve)
      .runSegment(0, 1)
  })
}

const fileLoadingCapability = async (fileRequest) => {
  var filesURL = new URL('/fixture/files', window.location.href);
  const data = await fetch(filesURL.href, {
    method: "POST",
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(fileRequest)
  })

  return await data.json()
}

const basicDecorator = (name, capability) => {
  window[name] = capability
}

ElmContext.registerFileLoadingCapability(basicDecorator, fileLoadingCapability)
