# elm-spec

Use elm-spec to write specs that describe the behavior of your Elm program. Why?

Once you have a suite of specs that describe the behavior of your Elm program, you're in a position
to change your code with confidence. Just run the spec suite to determine whether your program
still has all the behavior you've described in those specs.

When you can change your code with confidence, you're in a better position to refactor your code.

When you can refactor your code, you can manage and reduce complexity.

When you can manage and reduce complexity, you can continue to add new features with ease, even as the scope
of your program grows. 

Sure, but why use elm-spec?

- elm-spec allows you to describe behaviors that involve HTML, HTTP, Time, ports, commands, and subscriptions --
and there's no need to structure your code in any special way to do so (although you can if you wish).
- elm-spec does not simulate calls to your program's view and update or commands and subscriptions; the Elm runtime
handles all this just as it will when your program is executed on its own.
- elm-spec exercises your program in a DOM environment (JSOM or a web browser)
- elm-spec allows you to write specs that describe the behavior of parts of your program in isolation from others. This makes those specs easier to write and easier to understand.

In short, with elm-spec you can get the same level of confidence as you would from a browser-based
end-to-end testing tool like Cypress, without losing the convenience of tools like elm-test. You can
still write your tests in Elm, and you can still test parts of your code in isolation.


## Getting Started

1. Install `brian-watkins/elm-spec` as a test dependency.

2. Create a directory for your specs and add it to the `source-directories` in your `elm.json`.

3. Add a file called `Runner.elm` to your specs directory. It should look something like this:

```
port module Runner exposing (program, browserProgram)

import Spec exposing (Spec)
import Spec.Runner exposing (Message)

port elmSpecOut : Message -> Cmd msg
port elmSpecIn : (Message -> msg) -> Sub msg

config : Spec.Runner.Config msg
config =
  { send = elmSpecOut
  , outlet = elmSpecOut
  , listen = elmSpecIn
  }

program : List (Spec model msg) -> Program Spec.Runner.Flags (Spec.Runner.Model model msg) (Spec.Runner.Msg msg)
program specs =
  Spec.Runner.program config specs

browserProgram : List (Spec model msg) -> Program Spec.Runner.Flags (Spec.Runner.Model model msg) (Spec.Runner.Msg msg)
browserProgram specs =
  Spec.Runner.browserProgram config specs
```

You must create the `elmSpecOut` and `elmSpecIn` ports and provide them to `Spec.Runner.program` or `Spec.Runner.browserProgram` via a `Spec.Runner.Config` value. And, yes, `send` and `outlet` should reference the
very same port, `elmSpecOut`. 

Now you can write spec modules. Each spec module is an elm program and so must have a `main` function. To construct
the `main` function, just reference `program` or `browserProgram` from your `Runner.elm` and provide a `List` of
`Spec`s to run. 

Here's an example spec module:

```
module SampleSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Runner
import Main as App


clickSpec : Spec App.Model App.Msg
clickSpec =
  Spec.describe "an html program"
  [ scenario "a click event" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
      )
      |> when "the button is clicked three times"
        [ Markup.target << by [ id "my-button" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> it "renders the count" (
        Markup.observeElement
          |> Markup.query << by [ id "count-results" ]
          |> expect (Markup.hasText "You clicked the button 3 time(s)")
      )
    )
  ]

main =
  Runner.browserProgram
    [ clickSpec
    ]
```

## Running Specs

To run your specs, you need to install a runner. There are currently two options.

### elm-spec-runner

You can run your specs from the command line in a [JSDOM](https://github.com/jsdom/jsdom) environment.

```
$ npm install --save-dev elm-spec-runner
```

Then you can just run your specs like so:

```
$ npx elm-spec
```

See [elm-spec-runner](https://github.com/brian-watkins/elm-spec/tree/master/runner/elm-spec-runner) for more
details on command line options.

### karma-elm-spec-framework

You can also run your specs in a real browser via [Karma](http://karma-runner.github.io/latest/).

See [karma-elm-spec-framework](https://github.com/brian-watkins/elm-spec/tree/master/runner/karma-elm-spec-framework)
for more details.


## More Examples

For more examples, see the [specs for elm-spec](https://github.com/brian-watkins/elm-spec/tree/master/tests/src/Specs).

For a real-world test suite, see the [specs for a simple code-guessing game](https://github.com/brian-watkins/mindmaster).


## Extra

I suggest adding one more file to your spec suite -- `Spec/Extra.elm`

```
module Spec.Extra exposing
  ( equals
  )

import Spec.Claim as Claim exposing (Claim)

equals : a -> Claim a
equals =
  Claim.isEqual Debug.toString
```

Then, you can import the `equals` function from this library without having to write out
`Claim.isEqual Debug.toString` every time.
