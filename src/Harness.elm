module Harness exposing
  ( Config
  , expect, Expectation
  , browserHarness
  , Message
  , use, run, toRun, observe, toObserve, setup, toSetup
  )

{-| Harness

@docs Config, expose, browserHarness, expect, Expectation, Message
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


{-|
-}
type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }

{-| Represents a message to pass between elm-spec and the JavaScript elm-spec runner.
-}
type alias Message =
  Message.Message

type alias Msg msg =
  Program.Msg msg

type alias Model model msg =
  Program.Model model msg

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


run : List (Step model msg) -> HarnessExport model msg
run steps =
  Harness.Types.StepsExport <| \_ -> steps


toRun : (a -> List (Step model msg)) -> (Json.Decoder a -> HarnessExport model msg)
toRun generator =
  \decoder ->
    Harness.Types.StepsExport <| \value ->
      case Json.decodeValue decoder value of
        Ok config ->
          generator config
        Err message ->
          Debug.todo <| "Could not configure setup! " ++ Json.errorToString message


use : Json.Decoder a -> (Json.Decoder a -> HarnessExport model msg) -> HarnessExport model msg
use decoder generator =
  generator decoder


observe : Expectation model -> HarnessExport model msg
observe expectation =
  Harness.Types.ExpectationExport <| \_ -> expectation


toObserve : (a -> Expectation model) -> (Json.Decoder a -> HarnessExport model msg)
toObserve generator =
  \decoder ->
    Harness.Types.ExpectationExport <| \value ->
      case Json.decodeValue decoder value of
        Ok config ->
          generator config
        Err message ->
          Debug.todo <| "Could not configure setup! " ++ Json.errorToString message


setup : Setup model msg -> HarnessExport model msg
setup theSetup =
  Harness.Types.SetupExport <| \_ -> Ok theSetup


toSetup : (a -> Setup model msg) -> (Json.Decoder a -> HarnessExport model msg)
toSetup generator =
  \decoder ->
    Harness.Types.SetupExport <| \value ->
      case Json.decodeValue decoder value of
        Ok config ->
          Ok <| generator config
        Err message ->
          Err <| Report.note <| "Unable to configure setup: " ++ Json.errorToString message


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


{-|
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
