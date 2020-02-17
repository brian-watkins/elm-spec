# Elm-Spec Core

This library contains the core logic for running elm-spec suites. Runner applications
can use this library to run elm-spec suites in a particular environment.


### Basic Usage

1. Create an ElmContext with a DOM window object.
2. Use the Compiler to compile the code and evaluate it in the DOM window.
3. Construct a new SuiteRunner with the ElmContext and a Reporter.
4. Call `runAll()` on the SuiteRunner to run all the spec programs.


# Public API

You may import four modules from elm-spec-core:

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
  elmPath: './node_modules/.bin/elm'
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
  // run only scenarios tagged with one of these tags
  tags: [ 'my-tag', 'another-tag' ],

  // stop the test suite run after the first failure
  endOnFailure: true,
}
```

and `version` is just used for testing.

### Instance Methods

**suiteRunner#runAll()**

Execute all the compiled spec programs, one by one.

## Reporter

A Reporter is an object with the following functions:

```
{
  // Called at the start of a suite run.
  startSuite: () => {},

  // Called with an Observation after each expectation is evaluated.
  record: (observation) => {},

  // Called with a Report. If there is an error, the spec suite will immediately end.
  error: (err) => {},

  // Called with a Report.
  log: (report) => {},

  // Called at the end of the spec suite run.
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
  
  // The outcome of evaluating the expectation: ACCEPT or REJECT
  summary: 'ACCEPT',

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
