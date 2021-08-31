module Harness exposing
  ( expect, Expectation
  , browserHarness
  , Message, Msg, Model, Config, Flags
  , HarnessExport, use, run, toRun, observe, toObserve, setup, toSetup
  )

{-| Functions for writing a harness.

A harness is a collection of functions that can be exposed to a test on the Javascript side
using the `elm-spec-harness` package. See the README for that package for details on how to
get started.

# Expose Harness Functions
@docs HarnessExport, use, setup, toSetup, run, toRun, observe, toObserve

# Create an Expectation
@docs Expectation, expect 

# Create a Harness Program
@docs Config, browserHarness

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
import Spec.Report as Report
import Dict
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


-- requiredElmSpecCoreVersion : number
-- requiredElmSpecCoreVersion = 7


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


{-| Expose a list of steps to run.
-}
run : List (Step model msg) -> HarnessExport model msg
run steps =
  Harness.Types.StepsExport <| \_ -> Ok steps


{-| Expose a function that produces a list of steps to run based on some argument.

Compose this function with [Harness.use](#use) to provide a decoder for the argument.
-}
toRun : (a -> List (Step model msg)) -> (Json.Decoder a -> HarnessExport model msg)
toRun generator =
  \decoder ->
    Harness.Types.StepsExport <| \value ->
      case Json.decodeValue decoder value of
        Ok config ->
          Ok <| generator config
        Err message ->
          Err <| Report.note <| "Unable to configure steps: " ++ Json.errorToString message


{-| Provide a decoder for JSON data that will be used to configure some exported function.

For example:

    typeStuff : String -> List (Step Model Msg)
    typeStuff textToType =
      [ Spec.Markup.target << by [ id "input-field" ]
      , Spec.Markup.Event.input textToType
      ]


    Runner.browserHarness
      [ ( "typeStuff"
        , Harness.use Json.string <| Harness.toRun typeStuff
        )
      ]

-}
use : Json.Decoder a -> (Json.Decoder a -> HarnessExport model msg) -> HarnessExport model msg
use decoder generator =
  generator decoder


{-| Expose an expectation to observe.
-}
observe : Expectation model -> HarnessExport model msg
observe expectation =
  Harness.Types.ExpectationExport <| \_ -> Ok expectation


{-| Expose a function that produces an expectation to observe based on some argument.

Compose this function with [Harness.use](#use) to provide a decoder for the argument.
-}
toObserve : (a -> Expectation model) -> (Json.Decoder a -> HarnessExport model msg)
toObserve generator =
  \decoder ->
    Harness.Types.ExpectationExport <| \value ->
      case Json.decodeValue decoder value of
        Ok config ->
          Ok <| generator config
        Err message ->
          Err <| Report.note <| "Unable to configure expectation: " ++ Json.errorToString message


{-| Expose a `Setup` for a scenario.
-}
setup : Setup model msg -> HarnessExport model msg
setup theSetup =
  Harness.Types.SetupExport <| \_ -> Ok theSetup


{-| Expose a function that produces a `Setup` for a scenario based on some argument.

Compose this function with [Harness.use](#use) to provide a decoder for the argument.
-}
toSetup : (a -> Setup model msg) -> (Json.Decoder a -> HarnessExport model msg)
toSetup generator =
  \decoder ->
    Harness.Types.SetupExport <| \value ->
      case Json.decodeValue decoder value of
        Ok config ->
          Ok <| generator config
        Err message ->
          Err <| Report.note <| "Unable to configure setup: " ++ Json.errorToString message


{-| Represents an exposed function that can be executed from the Javascript side.
-}
type alias HarnessExport model msg
  = Harness.Types.HarnessExport model msg


collateExports : List (String, HarnessExport model msg) -> Program.Exports model msg
collateExports exports =
  { setups = 
      exports
        |> List.filterMap (\(name, export) ->
          case export of
            Harness.Types.SetupExport setupExport ->
              Just (name, setupExport)
            _ ->
              Nothing
        )
        |> Dict.fromList
  , steps = 
      exports
        |> List.filterMap (\(name, export) ->
          case export of
            Harness.Types.StepsExport stepsExport ->
              Just (name, stepsExport)
            _ ->
              Nothing
        )
        |> Dict.fromList
  , expectations =
      exports
        |> List.filterMap (\(name, export) ->
          case export of
            Harness.Types.ExpectationExport expectationExport ->
              Just (name, expectationExport)
            _ ->
              Nothing
        )
          |> Dict.fromList
  }


{-| Create a harness program that exposes functions to be called from the Javascript side, using
the `elm-spec-harness` package.

Once you've created the `Config` value, I suggest adding a function like so:

    browserHarness : List (String, HarnessExport model msg) -> Program Flags (Model model msg) (Msg msg)
    browserHarness =
      Harness.browserHarness config

Then, each of your harness modules can implement their own `main` function:

    main =
      Runner.browserHarness
        [ ... some exposed functions ...
        ]

Then use the `elm-spec-harness` package to call the exposed functions as necessary.

-}
browserHarness : Config msg -> List (String, HarnessExport model msg) -> Program Flags (Model model msg) (Msg msg)
browserHarness config exports =
  Browser.application
    { init = \_ _ key ->
        Program.init (Just key)
    , view = Program.view
    , update = Program.update config <| collateExports exports
    , subscriptions = Program.subscriptions config
    , onUrlRequest = Program.onUrlRequest
    , onUrlChange = Program.onUrlChange
    }
