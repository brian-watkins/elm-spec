module Harness exposing
  ( Config
  , expect, Expectation
  , expose
  , exposeSteps
  , browserHarness
  , Message
  )

{-| Harness

@docs Config, expose, browserHarness, expect, Expectation, Message
-}

import Spec.Message as Message
import Spec.Step exposing (Step)
import Harness.Program as Program
import Harness.Types as Harness
import Spec.Setup exposing (Setup)
import Spec.Observer as Observer exposing (Observer)
import Spec.Report as Report
import Spec.Claim exposing (Claim, Verdict(..))
import Spec.Observer.Internal as Observer
import Dict exposing (Dict)
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

type alias ExposedExpectation model =
  Json.Value -> Expectation model

{-| Represents what should be the case about some part of the world.

Expectations are checked at the end of the scenario, after all steps of the
script have been performed.
-}
type alias Expectation model =
  Harness.Expectation model


{-| Provide an observer with a claim to evaluate.
-}
expect : Claim a -> Observer model a -> Expectation model
expect claim observer =
  Harness.Expectation <| Observer.expect claim observer


{-|
-}
expose : Json.Decoder a -> (a -> Expectation model) -> ExposedExpectation model
expose decoder generator =
  \value ->
    case Json.decodeValue decoder value of
      Ok expected ->
        generator expected
      Err _ ->
        expect (\_ -> Reject <| Report.note "Could not decode value for expectation!") (Observer.observeModel identity)


type alias ExposedSteps model msg
  = List (Step model msg)


exposeSteps : List (Step model msg) -> ExposedSteps model msg
exposeSteps steps =
  steps


{-|
-}
browserHarness : Config msg -> Setup model msg -> Dict String (ExposedSteps model msg) -> Dict String (ExposedExpectation model) -> Program Flags (Model model msg) (Msg msg)
browserHarness config setup steps expectations =
  Browser.application
    { init = \_ _ _ ->
        Program.init setup 
    , view = Program.view
    , update = Program.update config steps expectations
    , subscriptions = Program.subscriptions config
    , onUrlRequest = Program.onUrlRequest
    , onUrlChange = Program.onUrlChange
    }
