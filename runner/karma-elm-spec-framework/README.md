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

Here's an example of the config properties relevant to elm-spec:

```
    frameworks: ['elm-spec'],

    elmSpec: {
      cwd: './specs',
      specs: './**/*Spec.elm',
      pathToElm: './node_modules/.bin/elm'
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

`elmSpec.cwd` specifies a root directory for your specs, that is, a directory that contains an `elm.json` file for
your specs. By default this value is `.`. 

You should be able to get by without specifying a special working directory, assuming your project's `elm.json` is
in the root directory of your project. Use the 
root `elm.json` by adding the directory with your specs to the `source-directories` portion of your
root `elm.json` and installing `brian-watkins/elm-spec` as a test dependency.

`elmSpec.specs` is a glob specifying the pattern to find all your spec programs. Note that this path is relative
to `elmSpec.cwd`. By default, this will look for specs at `./specs/**/*Spec.elm`.

`elmSpec.pathToElm` specifies the path to the elm binary. By default this will look for `elm` in your path.

`client.elmSpec.tags` is a list of tags. If these are specified, only those specs tagged with these tags will be executed.

`client.elmSpec.endOnFailure` is a boolean that tells elm-spec whether it should stop executing specs on the first failure.
This option is especially helpful to turn on when debugging failures, as you'll be able to see and interact with the
program under test (on the Karma debug page) when a spec fails in the browser Karma is controling.