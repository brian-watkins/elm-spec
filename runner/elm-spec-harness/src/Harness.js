const { Compiler } = require("elm-spec-core")

// This lives on the Node side
// probably shouldn't call it harness
// It really just compiles the elm code
// Maybe it could also append the browserAdapter code?
module.exports = class Harness {

  compile(path) {
    const compiler = new Compiler({
      cwd: "./test/browserTests/harness",
      specPath: path,
    })
  
    const compiledHarness = compiler.compile()

    return compiledHarness
  }
}