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

import Spec.Setup.Internal exposing (Setup, Subject, initializeSubject)
import Spec.Message as Message exposing (Message)
import Spec.Scenario.Message as Message
import Spec.Step.Message as Message
import Spec.Report as Report exposing (Report)
import Harness.Types exposing (ExposedSetup)
import Json.Decode as Json
import Browser.Navigation as Navigation


type alias Actions msg =
  { send: Message -> Cmd msg
  , finished: Cmd msg
  , listen: (Message -> Msg) -> Sub msg
  }


type alias Model model msg =
  { subject: Subject model msg
  , mode: InitializeMode
  }


type InitializeMode
  = ResetContext
  | Configure


harnessSubject : Model model msg -> Subject model msg
harnessSubject model =
  model.subject


type Msg
  = ResetComplete
  | ConfigureComplete
  | ReceivedMessage Message


type alias ExposedSetupRepository model programMsg =
  { get: String -> Maybe (ExposedSetup model programMsg)
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
    Nothing ->
      Err <| Report.note <| "No setup has been exposed with the name " ++ setupName


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
    ( ResetContext, ResetComplete ) ->
      ( { model | mode = Configure }
      , configureWith actions model.subject.configureEnvironment
      )
    ( Configure, ConfigureComplete ) ->
      ( model, actions.finished )
    _ ->
      ( model, Cmd.none )


configureWith : Actions msg -> List Message -> Cmd msg
configureWith actions configMessages =
  if List.isEmpty configMessages then
    actions.send Message.configureComplete
  else
    List.map Message.configMessage configMessages
      |> List.map actions.send
      |> Cmd.batch


subscriptions : Actions msg -> Model model programMsg -> Sub msg
subscriptions actions model =
  case model.mode of
    ResetContext ->
      actions.listen (\message -> 
        if Message.is "_scenario" "state" message then
          case Message.decode Json.string message |> Result.withDefault "" of
            "CONTINUE" ->
              ResetComplete
            _ ->
              ReceivedMessage message
        else
          ReceivedMessage message
      )
    Configure ->
      actions.listen (\message -> 
        if Message.is "_configure" "complete" message then
          ConfigureComplete
        else
          ReceivedMessage message
      )