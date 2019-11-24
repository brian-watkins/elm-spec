# Karma Elm Spec Framework

This is a plugin for [Karma](http://karma-runner.github.io/latest/) that allows you to 
run specs create with elm-spec.

### Getting Started

First, follow the instructions in elm-spec to set up your specs.

Then install Karma and the Elm Spec framework:

```
$ npm install --save-dev karma karma-chrome-launcher karma-elm-spec-framework
```

Create a `karma.conf.js` file in your project root (for example, by running `npx karma init`).

Here's a minimal example of the config properties relevant to elm-spec:

```
    frameworks: ['elm-spec'],

    elmSpec: {
      specRoot: './specs',
      specs: './**/*Spec.elm',
      pathToElm: 'elm'
    },

    client: {
      elmSpec: {
        tags: [ 'fun' ],
        endOnFailure: true
      }
    },

    files: [
      { pattern: 'src/elm/*.elm', included: false, served: false },
      { pattern: 'specs/**/*Spec.elm', included: false, served: false }
    ],

    preprocessors: {
      "**/*.elm": [ "elm-spec" ],
    },

    reporters: ['elm-spec'],
```

In the `files` and `preprocessors` section, specify the files you want Karma to watch for changes.

Note that we tell Karma not to serve these files. The elm-spec framework will take care
of loading the appropriate compiled elm code into the browser.

For best results, add elm-spec as your reporter.

Here are some elm-spec specific configuration properties:

`elmSpec.specRoot` specifies the root directory for your specs, that is, the directory that contains the `elm.json` file for
your specs.

`elmSpec.specs` is a glob specifying the pattern to find all your spec programs. Note that this path is relative
to `elmSpec.specRoot`

`elmSpec.pathToElm` specifies the path to the elm binary.

`client.elmSpec.tags` is a list of tags. If these are specified, only those specs tagged with these tags will be executed.

`client.elmSpec.endOnFailure` is a boolean that tells elm-spec whether it should stop executing specs on the first failure.
This option is especially helpful to turn on when debugging failures, as you'll be able to see and interact with the
program under test when a spec fails in the browser Karma is controling.