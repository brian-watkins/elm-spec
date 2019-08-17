
module.exports = class GlobalContext {
  constructor(compiler) {
    this.compiler = compiler
  }

  evaluate(evaluator) {
    if (!this.Elm) {
      this.compiler.compile()
        .then((compiledCode) => {
          eval(compiledCode)
          evaluator(this.Elm)
        })
        .catch((err) => {
          console.log(err)
          process.exit(1)
        })
      return
    }
    
    evaluator(this.Elm)
  }
}
