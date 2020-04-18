const Compiler = require('../src/compiler')
const chai = require('chai')
const expect = chai.expect
const path = require('path')


describe("compiler", () => {
  context("the spec path is not a real glob", () => {
    it("lists no files", () => {
      const window = compileSpecsAt("./tests/somePlace", "dsfsd/d///_")
      expect(window._elm_spec.compiler.files).to.have.length(0)
      expect(window._elm_spec.compiler.cwd).to.equal("./tests/somePlace")
      expect(window._elm_spec.compiler.specPath).to.equal("dsfsd/d///_")
    })
  })

  context("the spec path does not match any files", () => {
    it("lists no files", () => {
      const window = compileSpecsAt("./tests/sample", "./specs/NoFiles/*Spec.elm")
      expect(window._elm_spec.compiler.files).to.have.length(0)
      expect(window._elm_spec.compiler.cwd).to.equal("./tests/sample")
      expect(window._elm_spec.compiler.specPath).to.equal("./specs/NoFiles/*Spec.elm")
    })
  })

  context("when there are files but compilation fails", () => {
    it("lists the files", () => {
      const window = compileSpecsAt("./tests/sample", "./specs/WithCompilationError/**/*Spec.elm")
      
      const fullPathOne = path.resolve("./tests/sample/specs/WithCompilationError/ClickSpec.elm")
      const fullPathTwo = path.resolve("./tests/sample/specs/WithCompilationError/MoreBehaviors/AnotherSpec.elm")
      expect(window._elm_spec.compiler.files).to.deep.equal([fullPathOne, fullPathTwo])
      expect(window._elm_spec.compiler.cwd).to.equal("./tests/sample")
      expect(window._elm_spec.compiler.specPath).to.equal("./specs/WithCompilationError/**/*Spec.elm")
    })
  })
})

const compileSpecsAt = (cwd, specPath) => {
  const compiler = new Compiler({
    cwd,
    specPath,
    silent: true
  })

  const code = compiler.compile()

  let window = { _elm_spec: {} }
  eval(code)
  
  return window
}