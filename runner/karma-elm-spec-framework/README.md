# Karma Elm Spec Framework

This is a plugin for [Karma](http://karma-runner.github.io/latest/) that allows you to 
run specs created with elm-spec.

### Getting Started

First, follow the [instructions](https://github.com/brian-watkins/elm-spec) to set up your elm-spec specs.

Then install Karma and the Elm Spec framework:

```
$ npm install --save-dev karma karma-chrome-launcher karma-elm-spec-framework
```

Create a `karma.conf.js` file in your project root (for example, by running `npx karma init`).

Here's an example of the config properties relevant to elm-spec:

```
    frameworks: ['elm-spec'],

    // Optional elm-spec configuration
    elmSpec: {
      // Root directory for your specs; must contain elm.json.
      // By default this is './specs'
      cwd: './my-specs',

      // A glob to locate your spec modules, relative to the current
      // working directory.
      // By default, this is './**/*Spec.elm'
      specs: './SpecificBehavior/**/*Spec.elm',

      // Path to the elm executable
      // By default, this looks for elm on your path
      pathToElm: '/some/path/to/elm'
    },

    client: {
      // Optional elm-spec configuration
      elmSpec: {
        // Only scenarios tagged with one of these tags will be executed
        // By default, this is []
        tags: [ 'fun' ],

        // End the spec suite run on the first failure.
        // This is helpful to turn on when debugging failures, as you'll be able
        // to see and interact with the program under test (on the Karma debug
        // page) when a spec fails in the browser Karma is controling.
        // By default, this is false.
        endOnFailure: true,
      }
    },

    // These files will be watched for changes by Karma.
    // When they change, the elm files will be recompiled.
    // Tell Karma not to serve these files; the elm-spec framework takes care of
    // compiling and loading the correct files into the browser.
    files: [
      { pattern: 'src/elm/*.elm', included: false, served: false },
      { pattern: 'specs/**/*Spec.elm', included: false, served: false }
    ],

    // This ensures any changed elm files will trigger the spec files to be recompiled.
    preprocessors: {
      "**/*.elm": [ "elm-spec" ],
    },

    // For best results, use the included elm-spec reporter.
    reporters: ['elm-spec'],
```
