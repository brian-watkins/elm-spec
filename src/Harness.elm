module Harness exposing
  ( expect, Expectation
  , browserHarness
  , Message, Msg, Model, Config, Flags
  , HarnessExport, export
  , HarnessFunction, steps, stepsFrom, expectation, expectationFrom, setup, setupFrom
  )

{-| Functions for writing a harness.

A harness is a collection of functions that can be exposed to a test on the Javascript side
using the `elm-spec-harness` package. See the README for that package for details on how to
get started.

For example:

    typeStuff : String -> List (Step Model Msg)
    typeStuff textToType =
      [ Spec.Markup.target << by [ id "input-field" ]
      , Spec.Markup.Event.input textToType
      ]


    Runner.browserHarness
      [ Harness.stepsFrom Json.string typeStuff
          |> Harness.export "typeStuff"
      ]


# Expose Harness Functions
@docs HarnessExport, export
@docs HarnessFunction, steps, stepsFrom, expectation, expectationFrom, setup, setupFrom

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
import Spec.Version as Version
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


{-| Create a HarnessFunction that runs a list of steps.
-}
steps : List (Step model msg) -> HarnessFunction model msg
steps stepsToExpose =
  stepsFrom Json.value (\_ -> stepsToExpose)


{-| Create a Harnessfunction that runs a list of steps based on some argument
passed in from the Javascript side.

Provide a decoder for the argument.
-}
stepsFrom : Json.Decoder a -> (a -> List (Step model msg)) -> HarnessFunction model msg
stepsFrom decoder generator =
  Harness.Types.StepsFunction <| \value ->
    case Json.decodeValue decoder value of
      Ok config ->
        Ok <| generator config
      Err message ->
        Err <| Report.note <| "Unable to configure steps: " ++ Json.errorToString message


{-| Create a HarnessFunction that evaluates an expectation.
-}
expectation : Expectation model -> HarnessFunction model msg
expectation expectationToExpose =
  expectationFrom Json.value (\_ -> expectationToExpose)


{-| Create a HarnessFunction that evaluates an expectation that is generated based on some argument
passed in from the Javascript side.

Provide a decoder for the argument.
-}
expectationFrom : Json.Decoder a -> (a -> Expectation model) -> HarnessFunction model msg
expectationFrom decoder generator =
  Harness.Types.ExpectationFunction <| \value ->
    case Json.decodeValue decoder value of
      Ok config ->
        Ok <| generator config
      Err message ->
        Err <| Report.note <| "Unable to configure expectation: " ++ Json.errorToString message


{-| Create a HarnessFunction that executes a `Setup` for a scenario.
-}
setup : Setup model msg -> HarnessFunction model msg
setup theSetup =
  setupFrom Json.value (\_ -> theSetup)


{-| Create a HarnessFunction that executes a `Setup` for a scenario based on some argument
passed in from the Javascript side.

Provide a decoder for the argument.
-}
setupFrom : Json.Decoder a -> (a -> Setup model msg) -> HarnessFunction model msg
setupFrom decoder generator =
  Harness.Types.SetupFunction <| \value ->
    case Json.decodeValue decoder value of
      Ok config ->
        Ok <| generator config
      Err message ->
        Err <| Report.note <| "Unable to configure setup: " ++ Json.errorToString message


{-| Represents a function that can be exported.
-}
type alias HarnessFunction model msg
  = Harness.Types.HarnessFunction model msg


{-| Associates a HarnessFunction with a name by which it can be referenced
from the JavaScript side.
-}
type HarnessExport model msg
  = HarnessExport String (HarnessFunction model msg)


{-| Specify a name by which a HarnessFunction can be referenced from the
JavaScript side.
-}
export : String -> HarnessFunction model msg -> HarnessExport model msg
export name function =
  HarnessExport name function


collateExports : List (HarnessExport model msg) -> Program.Exports model msg
collateExports exports =
  { setups = 
      exports
        |> List.filterMap (\(HarnessExport name function) ->
          case function of
            Harness.Types.SetupFunction generator ->
              Just (name, generator)
            _ ->
              Nothing
        )
        |> Dict.fromList
  , steps = 
      exports
        |> List.filterMap (\(HarnessExport name function) ->
          case function of
            Harness.Types.StepsFunction generator ->
              Just (name, generator)
            _ ->
              Nothing
        )
        |> Dict.fromList
  , expectations =
      exports
        |> List.filterMap (\(HarnessExport name function) ->
          case function of
            Harness.Types.ExpectationFunction generator ->
              Just (name, generator)
            _ ->
              Nothing
        )
          |> Dict.fromList
  }


{-| Create a harness program that exposes functions to be called from the Javascript side, using
the `elm-spec-harness` package.

Once you've created the `Config` value, I suggest adding a function like so:

    browserHarness : List (HarnessExport model msg) -> Program Flags (Model model msg) (Msg msg)
    browserHarness =
      Harness.browserHarness config

Then, each of your harness modules can implement their own `main` function:

    main =
      Runner.browserHarness
        [ ... some exposed functions ...
        ]

Then use the `elm-spec-harness` package to call the exposed functions as necessary.

-}
browserHarness : Config msg -> List (HarnessExport model msg) -> Program Flags (Model model msg) (Msg msg)
browserHarness config exports =
  Browser.application
    { init = \flags _ key ->
        Program.init Version.core flags (Just key)
    , view = Program.view
    , update = Program.update config <| collateExports exports
    , subscriptions = Program.subscriptions config
    , onUrlRequest = Program.onUrlRequest
    , onUrlChange = Program.onUrlChange
    }
