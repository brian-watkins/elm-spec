const compiler = require('./src/compiler')
const Core = require('./src/core')
const Reporter = require('./src/reporter')

const reporter = new Reporter()

compiler.compile({
  specPath: "./src/Specs/*Spec.elm",
  elmPath: "../node_modules/.bin/elm",
  outputPath: "./compiled-specs.js"
}).then((Elm) => {
  var app = Elm.Specs.SpecSpec.init({
    flags: { specName: "scenarios" }
  })
  
  new Core(app)
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
})
