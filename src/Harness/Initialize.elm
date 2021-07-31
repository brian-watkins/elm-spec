module Harness.Initialize exposing
  ( Model
  , Msg(..)
  , ExposedSetupRepository
  , Actions
  , init
  , update
  , subscriptions
  , harnessSubject
  )

import Spec.Setup.Internal exposing (initializeSubject)
import Spec.Message as Message exposing (Message)
import Spec.Scenario.Message as Message
import Harness.Types exposing (ExposedSetup)
import Json.Decode as Json
import Spec.Setup.Internal exposing (Subject)

type alias Actions msg =
  { send: Message -> Cmd msg
  , finished: Cmd msg
  , listen: (Message -> Msg) -> Sub msg
  }


type Model model msg
  = ResetContext (Subject model msg)
  | Configure (Subject model msg)


harnessSubject : Model model msg -> Subject model msg
harnessSubject model =
  case model of
    ResetContext subject ->
      subject
    Configure subject ->
      subject


type Msg
  = ResetComplete
  | ConfigureComplete

-- This has to do several things
-- 1. (DONE) call startScenario to reset the context
-- 2. do something with flushing animation tasks I think
-- 3. (DONE) Initialize the setup
-- 4. Report on failure if necessary
-- 4. (DONE) Configure the context for the setup
-- 5. Send and wait for the initial command (this is done in the exercise state, called after this is finished)

-- Basically we will need a kind of state machine inside this state, since sending Continue is
-- how we know to go to the next step each time

type alias ExposedSetupRepository model programMsg =
  { get: String -> Maybe (ExposedSetup model programMsg)
  }


init : Actions msg -> ExposedSetupRepository model programMsg -> Message -> ( Model model programMsg, Cmd msg )
init actions setups message =
  let
    maybeSetup = Message.decode (Json.field "setup" Json.string) message
      |> Result.toMaybe
      |> Maybe.andThen setups.get
    maybeConfig = Message.decode (Json.field "config" Json.value) message
      |> Result.toMaybe
  in
    case Maybe.map2 (<|) maybeSetup maybeConfig of
      Just setup ->
        let
          maybeSubject =
            initializeSubject setup Nothing
              |> Result.toMaybe
        in
          case maybeSubject of
            Just subject ->
              -- note: Is this the best message to send out? Maybe 'configure'? or something?
              ( ResetContext subject, actions.send Message.startScenario )
            Nothing ->
              Debug.todo "Could not initialize subject!"
      Nothing ->
        Debug.todo "Could not decode setup config!"


update : Actions msg -> Msg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
update actions msg model =
  case ( model, msg ) of
    ( ResetContext subject, ResetComplete ) ->
      ( Configure subject
      , configureWith actions subject.configureEnvironment
      )
    ( Configure _, ConfigureComplete ) ->
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
  case model of
    ResetContext _ ->
      actions.listen (\message -> 
        if Message.is "_scenario" "state" message then
          case Message.decode Json.string message |> Result.withDefault "" of
            "CONTINUE" ->
              ResetComplete
            _ ->
              Debug.todo "Unexpected scenario state message in Harness Program!"
        else
          Debug.todo "Unknown message received in Initialize state!"
      )
    Configure _ ->
      actions.listen (\message -> 
        if Message.is "_configure" "complete" message then
          ConfigureComplete
        else
          Debug.todo "Unknown message received in Initialize state!"
      )