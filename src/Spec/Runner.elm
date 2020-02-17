module Spec.Runner exposing
  ( Message
  , Msg
  , Model
  , Config
  , Flags
  , program
  , browserProgram
  , pick
  )

{-| Use these functions and types to create the program that will run the spec suite.

See the README for a full example of how to use these functions to set up a
spec suite.

# Run Only Certain Scenarios
@docs pick

# Create a Spec Suite Program
@docs Config, browserProgram, program

# Spec Suite Program Types
@docs Message, Flags, Msg, Model

-}

import Spec exposing (Spec)
import Spec.Program as Program
import Spec.Message as Message
import Browser


requiredElmSpecCoreVersion = 5


{-| The spec suite runner must provide a Config, which must be implemented as follows:

Create two ports:

    port elmSpecOut : Message -> Cmd msg
    port elmSpecIn : (Message -> msg) -> Sub msg

And then create a `Config` like so:

    config : Spec.Runner.Config msg
    config =
      { send = elmSpecOut
      , outlet = elmSpecOut
      , listen = elmSpecIn
      }

The `send` and `outlet` attributes must reference the same port, `elmSpecOut`.

-}
type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , outlet: Message -> Cmd msg
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


{-| Represents a message to pass between elm-spec and the JavaScript elm-spec runner.
-}
type alias Message =
  Message.Message


{-| Flags that the JavaScript runner will pass to the spec suite program.
-}
type alias Flags =
  Program.Flags


{-| Used by the spec suite program.
-}
type alias Model model msg =
  Program.Model model msg


{-| Used by the spec suite program.
-}
type alias Msg msg =
  Program.Msg msg


{-| Create a spec suite program for describing the behavior of headless programs.

Once you've created the `Config` value, I suggest adding a function like so:

    program : List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
    program =
      Spec.Runner.program config

Then, each of your spec modules can implement their own `main` function:

    main =
      Runner.program
        [ ... some specs ...
        ]

The JavaScript runner will find each spec module and run it as its own program.

-}
program : Config msg -> List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
program config specs =
  Platform.worker
    { init = \flags -> Program.init (\_ -> specs) requiredElmSpecCoreVersion config flags Nothing
    , update = Program.update config
    , subscriptions = Program.subscriptions config
    }


{-| Create a spec suite program for describing the behavior of browser-based programs.

Once you've created the `Config` value, I suggest adding a function like so:

    program : List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
    program =
      Spec.Runner.browserProgram config

Then, each of your spec modules can implement their own `main` function:

    main =
      Runner.program
        [ ... some specs ...
        ]

The JavaScript runner will find each spec module and run it as its own program.

-}
browserProgram : Config msg -> List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
browserProgram config specs =
  Browser.application
    { init = \flags _ key -> Program.init (\_ -> specs) requiredElmSpecCoreVersion config flags (Just key)
    , view = Program.view
    , update = Program.update config
    , subscriptions = Program.subscriptions config
    , onUrlRequest = Program.onUrlRequest
    , onUrlChange = Program.onUrlChange
    }


{-| Pick this scenario to be executed when the spec suite runs.

When one or more scenarios are picked, only picked scenarios will be executed,
regardless of whether tags are specified via the spec runner.

Note that the first argument to this function must be a port defined like so:

    port elmSpecPick : () -> Cmd msg

I suggest adding a function to the main Runner file in your spec suite, where
you've defined your `Config` and so on:

    pick =
      Spec.Runner.pick elmSpecPick

Then, to pick a scenario to run, do something like this:

    myFunSpec =
      Spec.describe "Some fun stuff"
      [ Runner.pick <| Spec.scenario "fun things happen" (
          ...
        )
      ]

-}
pick : (() -> Cmd msg) -> Spec.Scenario model msg -> Spec.Scenario model msg
pick _ =
  Spec.tagged [ "_elm_spec_pick" ]