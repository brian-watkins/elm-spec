module Harness.Initialize exposing
  ( Model
  , Msg(..)
  , ExposedSetupRepository
  , Actions
  , generateSubject
  , init
  , update
  , subscriptions
  , harnessSubject
  )

import Spec.Setup.Internal exposing (Setup, Subject, Configuration(..), initializeSubject)
import Spec.Claim as Claim
import Spec.Setup.Message as Message
import Spec.Message as Message exposing (Message)
import Spec.Observer.Message as Message
import Spec.Scenario.Message as Message
import Spec.Step.Message as Message
import Spec.Report as Report exposing (Report)
import Harness.Errors as Errors
import Json.Decode as Json
import Browser.Navigation as Navigation
import Harness.Types exposing (HarnessFunction)


type alias Actions msg =
  { send: Message -> Cmd msg
  , sendToSelf: Msg -> Cmd msg
  , finished: Cmd msg
  , listen: (Message -> Msg) -> Sub msg
  }


type alias Model model msg =
  { subject: Subject model msg
  , mode: InitializeMode
  }


type InitializeMode
  = ResetContext
  | Configure (List Configuration)


harnessSubject : Model model msg -> Subject model msg
harnessSubject model =
  model.subject


type Msg
  = Continue
  | ReceivedMessage Message
  | Error Report


type alias ExposedSetupRepository model programMsg =
  { get: String -> Maybe (HarnessFunction (Setup model programMsg))
  }


generateSubject : ExposedSetupRepository model programMsg -> Maybe Navigation.Key -> Message -> Result Report (Subject model programMsg)
generateSubject setups maybeKey message =
  Result.map2 Tuple.pair
    ( Message.decode (Json.field "setup" Json.string) message )
    ( Message.decode (Json.field "config" Json.value) message )
    |> Result.mapError Report.note
    |> Result.andThen (tryToGenerateSetup setups)
    |> Result.andThen (tryToInitializeSubject maybeKey)


tryToGenerateSetup : ExposedSetupRepository model msg -> ( String, Json.Value ) -> Result Report (Setup model msg)
tryToGenerateSetup setups ( setupName, config ) =
  case setups.get setupName of
    Just setupGenerator ->
      setupGenerator config
        |> Result.mapError (Errors.configurationError "initial state" setupName)
    Nothing ->
      Err <| Errors.notFoundError "initial state" setupName


tryToInitializeSubject : Maybe Navigation.Key -> Setup model msg -> Result Report (Subject model msg)
tryToInitializeSubject maybeKey setup =
  initializeSubject setup maybeKey
    |> Result.mapError Report.note


init : Actions msg -> Subject model programMsg -> ( Model model programMsg, Cmd msg )
init actions subject =
  ( { subject = subject, mode = ResetContext }
  , actions.send Message.startScenario
  )


update : Actions msg -> Msg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
update actions msg model =
  case ( model.mode, msg ) of
    ( ResetContext, ReceivedMessage message ) ->
      if Message.is "start" "flush-animation-tasks" message then
        ( model
        , actions.send Message.runToNextAnimationFrame
        )
      else
        ( model, Cmd.none )
    ( ResetContext, Continue ) ->
      ( { model | mode = Configure model.subject.configurations }
      , actions.sendToSelf Continue
      )
    ( Configure configurations, Continue ) ->
      case configurations of
        [] ->
          ( model, actions.finished )
        configuration :: remaining ->
          case configuration of
            ConfigCommand message ->
              ( { model | mode = Configure remaining }
              , actions.send <| Message.configCommandMessage message
              )
            ConfigRequest message ->
              ( { model | mode = Configure remaining }
              , actions.send <| Message.configRequestMessage message
              )
    ( _, Error report ) ->
      ( model
      , actions.send <| Message.observation [] "Unable to start the scenario" <| Claim.Reject report
      )
    _ ->
      ( model, Cmd.none )


subscriptions : Actions msg -> Model model programMsg -> Sub msg
subscriptions actions _ =
  actions.listen <| \message ->
    if Message.is "_scenario" "state" message then
      case Message.decode Json.string message |> Result.withDefault "" of
        "CONTINUE" ->
          Continue
        _ ->
          ReceivedMessage message
    else if Message.is "_scenario" "abort" message then
      case Message.decode Report.decoder message of
        Ok report ->
          Error report
        Err error ->
          Error <| Report.fact "Could not decode a Step abort message" error
    else
      ReceivedMessage message