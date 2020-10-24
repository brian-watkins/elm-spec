# Elm-Spec Core

This library contains the core logic for running elm-spec suites. Runner applications
can use this library to run elm-spec suites in a particular environment.


### Basic Usage

For an elm-spec suite to run, some things need to happen in Node and some
things need to happen in a browser.

On the Node side:

1. Create a browser somehow (using JSDOM or Playwright or Puppeteer etc)
2. Prepare some JS that instantiates an ElmContext and a Reporter and uses those to create a SuiteRunner.
3. Bundle this JS (using Browserify etc) and evaluate it in the DOM window.
3. Use the Compiler to compile the code and evaluate it in the DOM window.

On the Browser side:

4. Call `runAll()` on the SuiteRunner to run all the spec programs.


# Public API

You may import these modules from elm-spec-core:

```
const {
  Compiler,
  ElmContext,
  SuiteRunner,
  ProgramRunner
} = require('elm-spec-core')
```

## Compiler

Create an instance:

```
new Compiler({
  // Switch to the given directory for compilation; must contain an elm.json file.
  // By default, the current working directory is `process.cwd()`
  cwd: './specs',

  // Glob that specifies how to find spec modules, relative to the current working directory
  // (REQUIRED)
  specPath: './**/*Spec.elm',

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

### Instance Methods

**compiler#compile()**

Compiles the spec modules into a single string of JavaScript, adds an elm-spec
specific wrapper around the compiled code to facilitate testing, and returns the string.


## ElmContext

Create an instance:

```
new ElmContext(window)
```

where `window` is a reference to the DOM window object belonging to the environment where the
compiled Elm code will be evaluated.

### Static Methods

**ElmContext#registerFileLoadingCapability(decorator, capability)**

Provide a decorator function that ElmContext can use to add a function to the window object. The `dectorator`
is a function that takes two arguments: the name of the function and the function itself. The implementation
of `decorator` should attach the given function to the window object using the given name.

`capability` in this case is a function that loads a file from the local filesystem. It takes a single argument
like so:

```
{ path: "some path to file", convertToText: true }
```

How the path is interpreted (what it is relative to, etc) is up to the implementation of the capability.

The capability implementation should return a promise. When `convertToText` is false it should resolve to:

```
{ path: "the absolute path to the file", buffer: { data: [1, 2, 3] } }
```

When `convertToText` is true, it should resolve to:

```
{ path: "the absolute path to the file", text: "the text of the file" }
```

If there is any problem loading the file, the promise should reject with this object:

```
{ type: "file", path: "the absolute path to the file" }
```

### Instance Methods

**elmContext#evaluate(callback)**

```
elmContext.evaluate((Elm) => {
  // do something with the Elm JavaScript object
})
```

## SuiteRunner

Create an instance:

```
new SuiteRunner(elmContext, reporter, options, version)
```

where `options` is:

```
{
  // stop the test suite run after the first failure
  endOnFailure: true,
}
```

and `version` is just used for testing.

### Instance Methods

**suiteRunner#runAll()**

Execute all the compiled spec programs, one by one.

**suiteRunner#runSegment(segment, totalSegments)**

Run only scenarios for the given segment. (eg, 0, 1, 2, ...)

## Reporter

A Reporter is an object with the following functions:

```
{
  // Called at the start of a suite run.
  // Note: this will be called once for each parallel segment.
  startSuite: () => {},

  // Called with an Observation after each expectation is evaluated.
  record: (observation) => {},

  // Called with a Report. If there is an error, the spec suite segment will immediately end.
  error: (err) => {},

  // Called with a Report.
  log: (report) => {},

  // Called at the end of the spec suite run.
  // Note: this will be called once for each parallel segment.
  finish: () => {}
}
```

## Observation

An object like this:

```
{
  // what is being described by the spec
  description: 'Some description',

  // steps in the scenario script
  conditions: [ 'Scenario: Some scenario', 'When something happens', 'it does something' ],
  
  // The outcome of the observation: ACCEPTED, SKIPPED, or REJECTED
  summary: 'ACCEPTED',

  // If the expectation is rejected, a report that explains why
  report: null,

  // Absolute path to the file containing the elm-spec program that produced this observation.
  modulePath: "/some/path/to/some/elm/SomeSpec.elm"
}
```

## Report

An object like this:

```
[
  {
    statement: "Expected",
    detail: "True"
  },
  { 
    statement: "to be",
    detail: "False"
  }
]
```

## ProgramRunner

Create an instance:

```
new ProgramRunner(app, elmContext, options)
```

where `app` is the initialized Elm program to execute, and options is the same options object used by SuiteRunner.

### Static Methods

**ProgramRunner#hasElmSpecPorts(app)**

Check if the app has the expected ports. Returns `true` or `false`.

### Instance Methods

**programRunner#run()**

Runs the spec program supplied in the constructor.

The following events are emitted:

`observation` -- emits an Observation object

`error` -- emits a Report describing the error

`log` -- emits a Report

`complete` -- the spec program run is complete; emits a boolean indicating whether the
next spec program (if any) should be executed. Under some conditions (like an error),
the ProgramRunner will indicate that no more spec programs should be executed.
