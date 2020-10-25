const Compiler = require('../src/compiler')
const chai = require('chai')
const expect = chai.expect
const path = require('path')


describe("compiler", () => {
  context("before compilation", () => {
    it("is in the ready state", () => {
      const compiler = new Compiler({
        cwd: ".",
        specPath: ".",
        logLevel: Compiler.LOG_LEVEL.SILENT
      })
      expect(compiler.status()).to.equal(Compiler.STATUS.READY)
    })
  })

  context("the spec path is not a real glob", () => {
    it("lists no files", () => {
      const { compiler, window } = compileSpecsAt("./tests/somePlace", "dsfsd/d///_")
      expect(compiler.status()).to.equal(Compiler.STATUS.NO_FILES)
      expect(window._elm_spec.compiler.files).to.have.length(0)
      expect(window._elm_spec.compiler.cwd).to.equal("./tests/somePlace")
      expect(window._elm_spec.compiler.specPath).to.equal("dsfsd/d///_")
    })
  })

  context("the spec path does not match any files", () => {
    it("lists no files", () => {
      const { compiler, window } = compileSpecsAt("./tests/sample", "./specs/NoFiles/*Spec.elm")
      expect(compiler.status()).to.equal(Compiler.STATUS.NO_FILES)
      expect(window._elm_spec.compiler.files).to.have.length(0)
      expect(window._elm_spec.compiler.cwd).to.equal("./tests/sample")
      expect(window._elm_spec.compiler.specPath).to.equal("./specs/NoFiles/*Spec.elm")
    })
  })

  context("when there are files but compilation fails", () => {
    it("lists the files", () => {
      const { compiler, window } = compileSpecsAt("./tests/sample", "./specs/WithCompilationError/**/*Spec.elm")
      
      expect(compiler.status()).to.equal(Compiler.STATUS.COMPILATION_FAILED)

      const fullPathOne = path.resolve("./tests/sample/specs/WithCompilationError/ClickSpec.elm")
      const fullPathTwo = path.resolve("./tests/sample/specs/WithCompilationError/MoreBehaviors/AnotherSpec.elm")
      expect(window._elm_spec.compiler.files).to.deep.equal([fullPathOne, fullPathTwo])
      expect(window._elm_spec.compiler.cwd).to.equal("./tests/sample")
      expect(window._elm_spec.compiler.specPath).to.equal("./specs/WithCompilationError/**/*Spec.elm")
    })
  })

  context("when compilation succeeds", () => {
    it("provides the correct status", () => {
      const { compiler } = compileSpecsAt("./tests/sample", "./specs/Passing/**/*Spec.elm")
      expect(compiler.status()).to.equal(Compiler.STATUS.COMPILATION_SUCCEEDED)
    })
  })
})

const compileSpecsAt = (cwd, specPath) => {
  const compiler = new Compiler({
    cwd,
    specPath,
    logLevel: Compiler.LOG_LEVEL.SILENT
  })

  const code = compiler.compile()

  let window = { _elm_spec: {} }
  try {
    eval(code)
  } catch (err) {}
  
  return { compiler, window }
}