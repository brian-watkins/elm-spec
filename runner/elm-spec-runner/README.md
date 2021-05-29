elm-spec-runner
===============

Node CLI for Elm-Spec

## Install

```
$ npm install --save-dev elm-spec-runner
```

## Usage

Use elm-spec-runner to run elm-spec suites from the command line.

```
$ elm-spec [options]
```

By default, elm-spec executes a spec suite in [JSDOM](https://github.com/jsdom/jsdom).
Note that while this is probably the fastest way to execute specs,
JSDOM does have limitations. For example, JSDOM does not calculate layout positions for HTML elements,
so any specs that describe layout in precise ways may fail unexpectedly.

For the most realistic execution environment, you should run specs in a real browser. To run your
specs in [Chromium](https://www.chromium.org/Home), simply provide `chromium` (or another valid
value) for the `--browser` option.

Note: `elm-spec` will result in a non-zero exit code if any observations are rejected or an error prevents
the spec suite from running to completion.

### Options

`--elm` -- Specify path to elm executable. Defaults to `elm`

`--specRoot` -- Specify the root directory for specs; should contain the elm.json file for the specs. Defaults to `./specs`

`--specs` -- Specify a glob for spec modules, relative to `specRoot`. Defaults to `./**/*Spec.elm`

`--browser` -- Specify the browser environment for the specs: `jsdom`, `chromium`, `webkit`, `firefox`. Defaults to `jsdom`

`--visible` -- Show the browser while the specs are running. Does nothing if the browser is `jsdom`.

`--watch` -- Rerun the spec when files change in directories listed in the `source-directories` of your specs' elm.json file.

`--parallel` -- Run scenarios in parallel, up to the number of CPU cores. This can lower spec suite
run time for larger spec suites.

`--endOnFailure` -- Stop the spec suite run on the first failure.

`--css` -- Path to a CSS file to load in the browser, relative to the current directory. You may specify multiple css files.

`--help` -- Print options