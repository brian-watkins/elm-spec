elm-spec-runner
===============

Node CLI for Elm-Spec

## Install

```
$ npm install --save-dev elm-spec-runner
```

## Usage

Use elm-spec-runner to run elm-spec suites from the command line in the [JSDOM](https://github.com/jsdom/jsdom) environment.

```
$ elm-spec [options]
```

### Options

`--help` -- Print options

`--cwd` -- Specify a different working directory; should contain the elm.json file for the specs.

`--elm` -- Specify path to elm executable. Defaults to `elm`

`--specs` -- Specify a glob for spec modules. Defaults to `./specs/**/*Spec.elm`

`--tag` -- Specify a tag. Only scenarios with this tag will be executable. You may specify several tags.

`--endOnFailure` -- Stop the spec suite run on the first failure. Defaults to `false`
