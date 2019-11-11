
module.exports = class GlobalContext {
  constructor(compiler) {
    this.compiler = compiler
  }

  evaluate(evaluator) {
    if (!this.Elm) {
      try {
        eval(this.compiler.compile())
        evaluator(this.Elm)
      } catch (error) {
        console.log(error)
        process.exit(1)
      }
      return
    }
    
    evaluator(this.Elm)
  }

  prepareForScenario() {
    //nothing
  }
}
