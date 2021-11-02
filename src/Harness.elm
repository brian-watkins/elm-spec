module Harness exposing
  ( expect, Expectation
  , browserHarness
  , Message, Msg, Model, Config, Flags
  , Harness, Definition, define, assign
  )

{-| Functions for writing a harness.

A harness is a collection of values and functions that can be exposed to a test on the
Javascript side using the `elm-spec-harness` package. See the README for that package
for details on how to get started.

For example:

    typeStuff : String -> List (Step Model Msg)
    typeStuff textToType =
      [ Spec.Markup.target << by [ id "input-field" ]
      , Spec.Markup.Event.input textToType
      ]


    Runner.browserHarness
      { initialStates = []
      , scripts =
        [ define "typeStuff" Json.string typeStuff
        ]
      , expectations = []
      }


# Define Harness Elements
@docs Definition, assign, define

# Create an Expectation
@docs Expectation, expect 

# Create a Harness Program
@docs Harness, Config, browserHarness

# Harness Program Types
@docs Message, Flags, Msg, Model

-}

import Spec.Message as Message
import Spec.Step exposing (Step)
import Harness.Program as Program
import Harness.Types
import Spec.Setup exposing (Setup)
import Spec.Observer as Observer exposing (Observer)
import Spec.Claim exposing (Claim, Verdict(..))
import Spec.Observer.Internal as Observer
import Spec.Version as Version
import Json.Decode as Json
import Browser


{-| The harness runner must provide a Config, which must be implemented as follows:

Create two ports:

    port elmSpecOut : Message -> Cmd msg
    port elmSpecIn : (Message -> msg) -> Sub msg

And then create a `Config` like so:

    config : Harness.Config msg
    config =
      { send = elmSpecOut
      , listen = elmSpecIn
      }

-}
type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


{-| Represents a message to pass between elm-spec and the JavaScript elm-spec runner.
-}
type alias Message =
  Message.Message


{-| Used by the harness program.
-}
type alias Msg msg =
  Program.Msg msg

{-| Used by the harness program.
-}
type alias Model model msg =
  Program.Model model msg


{-| Flags that the JavaScript runner will pass to the spec suite program.
-}
type alias Flags =
  Program.Flags


{-| Represents what should be the case about some part of the world.

Expectations are checked at the end of the scenario, after all steps of the
script have been performed.
-}
type alias Expectation model =
  Harness.Types.Expectation model


{-| Provide an observer with a claim to evaluate.
-}
expect : Claim a -> Observer model a -> Expectation model
expect claim observer =
  Harness.Types.Expectation <| Observer.expect claim observer


{-| Configure a harness with a set of initial states, scripts, and expectations.
-}
type alias Harness model msg =
  { initialStates: List (Definition (Setup model msg))
  , scripts: List (Definition (List (Step model msg)))
  , expectations: List (Definition (Expectation model))
  }


{-| Represents a function exposed as part of a harness.
-}
type alias Definition b =
  Harness.Types.Definition b


{-| Assign a name to a value so that it can be referenced as part of a harness.

Use this function to create a definition for a `Setup`, list of `Steps` or an
`Expectation` that you don't need to configure from the Javascript side.

For example, if you have the following value:

    clickButton : List (Step Model Msg)
    clickButton =
      [ Spec.Markup.target << by [ tag "button" ]
      , Spec.Markup.Event.click
      ]

You can create a definition to expose it as part of the harness under the
name "click" like so:

    definition =
      assign "click" clickButton

-}
assign : String -> b -> Definition b
assign name value =
  Harness.Types.Definition name <| \_ -> Ok value


{-| Define a JSON decoder for a function that takes one argument and assign this to a
name so that the function can be triggered as part of a harness.

Use this function to create a definition for a `Setup`, list of `Steps`, or an
`Expectation` that requires some input from the Javascript side.

For example, if you have the following function:

    typeSomething : String -> List (Step Model Msg)
    typeSomething text =
      [ Spec.Markup.target << by [ id "input-field" ]
      , Spec.Markup.Event.input text
      ]

You can create a definition to expose it as part of the harness under the
name "typeText" like so:

    definition =
      define "typeText" Json.string typeSomething

-}
define : String -> Json.Decoder a -> (a -> b) -> Definition b
define name decoder generator =
  Harness.Types.Definition name <| \value ->
    case Json.decodeValue decoder value of
      Ok config ->
        Ok <| generator config
      Err message ->
        Err <| Json.errorToString message


{-| Create a harness program that exposes values to be referenced and functions to be called
from the Javascript side, using the `elm-spec-harness` package.

Once you've created the `Config` value, I suggest adding a function like so:

    browserHarness : List (HarnessExport model msg) -> Program Flags (Model model msg) (Msg msg)
    browserHarness =
      Harness.browserHarness config

Then, each of your harness modules can implement their own `main` function:

    main =
      Runner.browserHarness
        { initialStates = myListOfInitialStates
        , scripts = myListOfScripts
        , expectations = myListOfExpectations
        }

Then use the `elm-spec-harness` package to use the exposed definitions as necessary.

-}
browserHarness : Config msg -> Harness model msg -> Program Flags (Model model msg) (Msg msg)
browserHarness config harness =
  Browser.application
    { init = \flags _ key ->
        Program.init Version.core flags (Just key)
    , view = Program.view
    , update = Program.update config harness
    , subscriptions = Program.subscriptions config
    , onUrlRequest = Program.onUrlRequest
    , onUrlChange = Program.onUrlChange
    }
