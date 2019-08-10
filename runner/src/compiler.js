const compiler = require("node-elm-compiler/dist/index")
const glob = require("glob")

exports.compile = ({ specPath, elmPath, outputPath }) => {
  return new Promise((resolve, reject) => {
    if (this.Elm) {
      resolve(this.Elm)
      return
    }

    glob(specPath, (err, files) => {
      if (err) reject(err)
      
      compiler.compileToString(files, {
        pathToElm: elmPath,
        output: outputPath
      })
      .then((data) => {
        eval(data.toString())
        resolve(this.Elm)
      })
      .catch((compileError) => {
        reject(compileError)
      })
    })
  })  
}
