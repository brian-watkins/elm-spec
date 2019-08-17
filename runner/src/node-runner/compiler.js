const compiler = require("node-elm-compiler/dist/index")
const glob = require("glob")

module.exports = class Compiler {
  constructor ({ specPath, elmPath, outputPath }) {
    this.specPath = specPath
    this.elmPath = elmPath
    this.outputPath = outputPath
  }

  compile() {
    return new Promise((resolve, reject) => {
      glob(this.specPath, (err, files) => {
        if (err) reject(err)
        
        compiler.compileToString(files, {
          pathToElm: this.elmPath,
          output: this.outputPath
        })
        .then((data) => {
          // this.compiledCode = data.toString()
          resolve(data.toString())
            // eval(data.toString())
            // resolve(this.Elm)
        })
        .catch((compileError) => {
          reject(compileError)
        })
      })  
    })
  }
}

// exports.compile = ({ specPath, elmPath, outputPath }) => {
//   return new Promise((resolve, reject) => {
//     // if (this.Elm) {
//       // resolve(this.Elm)
//       // return
//     // }
//     // if (this.compiledCode) {
//     //   resolve(this.compiledCode)
//     // }

//     glob(specPath, (err, files) => {
//       if (err) reject(err)
      
//       compiler.compileToString(files, {
//         pathToElm: elmPath,
//         output: outputPath
//       })
//       .then((data) => {
//         this.compiledCode = data.toString()
//         resolve(this.compiledCode)
//           // eval(data.toString())
//           // resolve(this.Elm)
//       })
//       .catch((compileError) => {
//         reject(compileError)
//       })
//     })
//   })  
// }
