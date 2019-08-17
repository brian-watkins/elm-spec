const Compiler = require('./compiler')
const SpecRunner = require('../core/runner')
const Reporter = require('./reporter')
const HtmlContext = require('./htmlContext')
const HtmlPlugin = require('../core/htmlPlugin')

const compiler = new Compiler({
  specPath: "./src/Specs/*Spec.elm",
  elmPath: "../node_modules/.bin/elm",
  outputPath: "./compiled-specs.js"
})

const htmlContext = new HtmlContext(compiler)

const plugins = {
  "_html": new HtmlPlugin(htmlContext.document())
}

htmlContext.evaluate(function (Elm) {
  var app = Elm.Specs.HtmlSpec.init({
    node: htmlContext.document().getElementById('app'),
    flags: { specName: "failing" }
  })

  const reporter = new Reporter(console.log)

  new SpecRunner(app, plugins)
    .on("observation", (observation) => {
      reporter.record(observation)
    })
    .on("complete", () => {
      console.log("Finished!")
      console.log(`Accepted: ${reporter.accepted}`)
      console.log(`Rejected: ${reporter.rejected}`)
    })
    .on("error", (error) => {
      console.log("Error:", error )
    })
    .run()

  app.ports.sendIn.send({ home: "_spec", name: "state", body: "START" })
})
