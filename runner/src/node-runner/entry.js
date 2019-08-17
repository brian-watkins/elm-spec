const SpecRunner = require('../core/runner')
const Reporter = require('./reporter')


// It could be that we just ALWAYS run in JSDOM. 
// But I kind of want elm-spec to be agnostic to the view ... 


// This depends on whether you are doing a browser program or a pure worker
// so the app construction needs to be in whatever code uses the compiler

// var app = Elm.Specs.HtmlSpec.init({
//   node: document.getElementById('app'),
//   flags: { specName: "failing" }
// })

// This is all context agnostic --> It just needs to be given an app object
// So we could wrap it in a function. 

// const reporter = new Reporter(console.log)

// new SpecRunner(app)
//   .on("observation", (observation) => {
//     reporter.record(observation)
//   })
//   .on("complete", () => {
//     console.log("Finished!")
//     console.log(`Accepted: ${reporter.accepted}`)
//     console.log(`Rejected: ${reporter.rejected}`)
//   })
//   .on("error", (error) => {
//     console.log("Error:", error )
//   })
//   .run()

// app.ports.sendIn.send({ home: "_spec", name: "state", body: "START" })
