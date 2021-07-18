const { Compiler } = require("elm-spec-core")
const fs = require("fs")
const path = require("path")

module.exports = class Harness {

  compile(harnessPath) {
    const adapter = fs.readFileSync(path.join(__dirname, "browserAdapter.js"))

    const compiler = new Compiler({
      cwd: "./test/browserTests/harness",
      specPath: harnessPath,
    })
  
    const compiledHarness = compiler.compile()

    return adapter + "\n\n" + compiledHarness
  }
}