module Harness.Initialize exposing
  ( Model
  , Msg(..)
  , Actions
  , init
  , update
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
  }


type alias Model model msg =
  { subject: Subject model msg
  }

type Msg
  = ReceivedMessage Message

-- This has to do several things
-- 1. call startScenario to reset the context
-- 2. do something with flushing animation tasks I think
-- 3. Initialize the setup (and report on failure if necessary)
-- 4. Configure the context for the setup
-- 5. Send and wait for the initial command (this is done in the exercise state, called after this is finished)

-- Basically we will need a kind of state machine inside this state, since sending Continue is
-- how we know to go to the next step each time

init : Actions msg -> ExposedSetup model programMsg -> Message -> ( Model model programMsg, Cmd msg )
init actions setupGenerator message =
  case Message.decode (Json.field "config" Json.value) message of
    Ok setupConfig ->
      let
        maybeSubject = 
          initializeSubject (setupGenerator setupConfig) Nothing
            |> Result.toMaybe
      in
        case maybeSubject of
          Just subject ->
            -- note: Is this the best message to send out? Maybe 'configure'? or something?
            ( { subject = subject }, actions.send Message.startScenario )
          Nothing ->
            Debug.todo "Could not initialize subject!"
    Err _ ->
      Debug.todo "Could not decode setup config!"


update : Actions msg -> Msg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
update actions msg model =
  case msg of
    ReceivedMessage message ->
      if Message.is "_scenario" "state" message then
        case Message.decode Json.string message |> Result.withDefault "" of
          "CONTINUE" ->
            ( model, actions.finished )
          _ ->
            Debug.todo "Unexpected scenario state message in Harness Program!"
      else
        ( model, Cmd.none )