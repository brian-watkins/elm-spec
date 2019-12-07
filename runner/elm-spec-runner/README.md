elm-spec-runner
===============

Node CLI for Elm-Spec

[![oclif](https://img.shields.io/badge/cli-oclif-brightgreen.svg)](https://oclif.io)
[![Version](https://img.shields.io/npm/v/elm-spec-runner.svg)](https://npmjs.org/package/elm-spec-runner)
[![Downloads/week](https://img.shields.io/npm/dw/elm-spec-runner.svg)](https://npmjs.org/package/elm-spec-runner)
[![License](https://img.shields.io/npm/l/elm-spec-runner.svg)](https://github.com/brian-watkins/elm-spec/blob/master/package.json)

<!-- toc -->
# Usage

Use elm-spec-runner to run elm-spec suites from the command line in the [jsdom](https://github.com/jsdom/jsdom) environment.

```
$ elm-spec [options]
```

### Options

`--help` -- Print options

`--elm` -- Specify path to elm executable. Defaults to `elm`

`--specs` -- Specify a glob for spec modules. Defaults to `./specs/**/*Spec.elm`

`--tag` -- Specify a tag. Only scenarios with this tag will be executable. You may specify several tags.

`--endOnFailure` -- Stop the spec suite run on the first failure. Defaults to `false`

`--timeout` -- Timeout in milliseconds for a scenario. Defaults to 500ms
