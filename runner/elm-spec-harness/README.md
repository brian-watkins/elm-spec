# elm-spec-harness

elm-spec-harness is a library that allows you to exercise and observe an Elm program as part
of a larger Javascript test suite.

To create a harness and use it in your Javascript tests you'll need to do a few things, in
this order:

1. Compile the Elm code
2. Evaluate the compiled Elm code in the browser
3. Bundle and load your tests into the browser
4. Run your tests

For an example of how to accomplish this using Playwright and esbuild, see
[runTest.js](https://github.com/brian-watkins/elm-spec/tree/master/runner/elm-spec-harness/test/runTest.js).

### Compiling

To compile the Elm code for your harness, create an instance of the `Compiler` object:

```
const Compiler = require('elm-spec-harness/compiler')

const compiler = new Compiler({
  // Switch to the given directory for compilation; must contain an elm.json file.
  // By default, the current working directory is `process.cwd()`
  cwd: './specs',

  // Glob that specifies how to find harness modules, relative to the current working directory
  // (REQUIRED)
  harnessPath: './**/Harness.elm',

  // Path to the elm executable
  // By default, the compiler uses the `elm` executable in the current path
  elmPath: './node_modules/.bin/elm',

  // Log level
  // By default, the compiler prints all log output
  // Compiler.LOG_LEVEL.ALL -- will print info and errors
  // Compiler.LOG_LEVEL.QUIET -- will only print compiler errors
  // Compiler.LOG_LEVEL.SILENT -- will print nothing at all
  logLevel: Compiler.LOG_LEVEL.QUIET
})
```

Then to compile the code:

```
const compiledElmCode = compiler.compile()
```

To find the status of the latest compile:

```
const status = compiler.status()
```

Possible values for `status` are:

```
// no compilation has occurred
Compiler.STATUS.READY

// no files found to compile
Compiler.STATUS.NO_FILES

// files were found and successfully compiled
Compiler.STATUS.COMPILATION_SUCCEEDED

// files were found but compilation failed
Compiler.STATUS.COMPILATION_FAILED
```