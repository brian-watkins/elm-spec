module Harness.Initialize exposing
  ( Model
  , Msg(..)
  , ExposedSetupRepository
  , Actions
  , init
  , update
  , subscriptions
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


type alias Model model msg =
  { subject: Subject model msg
  }

type Msg
  = Continue

-- This has to do several things
-- 1. call startScenario to reset the context
-- 2. do something with flushing animation tasks I think
-- 3. Initialize the setup (and report on failure if necessary)
-- 4. Configure the context for the setup
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
              ( { subject = subject }, actions.send Message.startScenario )
            Nothing ->
              Debug.todo "Could not initialize subject!"
      Nothing ->
        Debug.todo "Could not decode setup config!"


update : Actions msg -> Msg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
update actions msg model =
  case msg of
    Continue ->
      ( model, actions.finished )


subscriptions : Actions msg -> Model model programMsg -> Sub msg
subscriptions actions _ =
  actions.listen (\message -> 
    if Message.is "_scenario" "state" message then
      case Message.decode Json.string message |> Result.withDefault "" of
        "CONTINUE" ->
          Continue
        _ ->
          Debug.todo "Unexpected scenario state message in Harness Program!"
    else
      Debug.todo "Unexpected message in Harness Program!"
  )