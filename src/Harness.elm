module Harness exposing
  ( expect, Expectation
  , browserHarness
  , Message, Msg, Model, Config, Flags
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
      [ ( "typeStuff"
        , Harness.stepsFrom Json.string typeStuff
        )
      ]


# Expose Harness Functions
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
steps : List (Step model msg) -> HarnessFunction model msg
steps stepsToExpose =
  stepsFrom Json.value (\_ -> stepsToExpose)


{-| Expose a function that produces a list of steps to run based on some argument
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


{-| Expose an expectation to observe.
-}
expectation : Expectation model -> HarnessFunction model msg
expectation expectationToExpose =
  expectationFrom Json.value (\_ -> expectationToExpose)


{-| Expose a function that produces an expectation to observe based on some argument
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


{-| Expose a `Setup` for a scenario.
-}
setup : Setup model msg -> HarnessFunction model msg
setup theSetup =
  setupFrom Json.value (\_ -> theSetup)


{-| Expose a function that produces a `Setup` for a scenario based on some argument
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


{-| Represents an exposed function that can be executed from the Javascript side.
-}
type alias HarnessFunction model msg
  = Harness.Types.HarnessFunction model msg


collateExports : List (String, HarnessFunction model msg) -> Program.Exports model msg
collateExports exports =
  { setups = 
      exports
        |> List.filterMap (\(name, export) ->
          case export of
            Harness.Types.SetupFunction setupExport ->
              Just (name, setupExport)
            _ ->
              Nothing
        )
        |> Dict.fromList
  , steps = 
      exports
        |> List.filterMap (\(name, export) ->
          case export of
            Harness.Types.StepsFunction stepsExport ->
              Just (name, stepsExport)
            _ ->
              Nothing
        )
        |> Dict.fromList
  , expectations =
      exports
        |> List.filterMap (\(name, export) ->
          case export of
            Harness.Types.ExpectationFunction expectationExport ->
              Just (name, expectationExport)
            _ ->
              Nothing
        )
          |> Dict.fromList
  }


{-| Create a harness program that exposes functions to be called from the Javascript side, using
the `elm-spec-harness` package.

Once you've created the `Config` value, I suggest adding a function like so:

    browserHarness : List (String, HarnessFunction model msg) -> Program Flags (Model model msg) (Msg msg)
    browserHarness =
      Harness.browserHarness config

Then, each of your harness modules can implement their own `main` function:

    main =
      Runner.browserHarness
        [ ... some exposed functions ...
        ]

Then use the `elm-spec-harness` package to call the exposed functions as necessary.

-}
browserHarness : Config msg -> List (String, HarnessFunction model msg) -> Program Flags (Model model msg) (Msg msg)
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
