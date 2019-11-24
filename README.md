# Elm Spec

A fun way to describe the behavior of your Elm programs.

### Getting Started

Create a directory for your specs, move to that directory, and initialize an elm project

```
$ mkdir specs
$ cd specs
$ elm init
```

In your `elm.json` add the directory containing the source of the program you want to observe to the `source-directories`.

Install elm-spec:

```
$ elm install brian-watkins/elm-spec
```

Add two files: `src/Runner.elm` and `src/Spec/Extra.elm`

Then you'll need to install a runner for your specs via NPM.

Right now there are two options:

- elm-spec-runner -- Run your specs in jsdom
- karma-elm-spec-framework -- Run your specs via [Karma](http://karma-runner.github.io/latest/)

Follow the instructions for the specific runner to run your specs.

### Run tests

```
$ npm test
```