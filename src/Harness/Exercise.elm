module Harness.Exercise exposing
  ( Model, Msg(..)
  , Actions
  , ExposedStepsRepository
  , defaultModel
  , init
  , initForInitialCommand
  , update
  )

import Spec.Message as Message exposing (Message)
import Harness.Types exposing (..)
import Spec.Step exposing (Step)
import Spec.Step.Command as Step
import Spec.Step.Message as Message
import Json.Decode as Json
import Spec.Setup.Internal exposing (Subject)
import Spec.Step.Context exposing (Context)


type alias Model model programMsg =
  { stepsToRun: List (Step model programMsg)
  }


defaultModel : Model model programMsg
defaultModel =
  { stepsToRun = []
  }


type Msg programMsg
  = Continue
  | ReceivedMessage Message


type alias Actions msg programMsg =
  { send: Message -> Cmd msg
  , programMsg: programMsg -> msg
  , storeEffect: Message -> Cmd msg
  , continue: Cmd msg
  , finished: Cmd msg
  }


type alias ExposedStepsRepository model msg =
  { get: String -> Maybe (ExposedSteps model msg)
  }


init : Actions msg programMsg -> ExposedStepsRepository model programMsg -> Model model programMsg -> Message -> ( Model model programMsg, Cmd msg )
init actions steps model message =
  let
    maybeSteps = Message.decode (Json.field "steps" Json.string) message
      |> Result.toMaybe
      |> Maybe.andThen (\observerName -> steps.get observerName)
  in
    case maybeSteps of
      Just stepsToRun ->
        ( { model | stepsToRun = stepsToRun }
        , actions.continue
        )
      Nothing ->
        Debug.todo "Could not find steps!"


initForInitialCommand : Actions msg programMsg -> Subject model programMsg -> ( Model model programMsg, Cmd msg )
initForInitialCommand actions _ =
  -- note that we need to replace this with subject.initialCommand when we have a test for it
  ( { defaultModel | stepsToRun = [ \_ -> Step.sendToProgram Cmd.none ] }
  , actions.continue
  )


update : Actions msg programMsg -> Context model -> Msg programMsg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
update actions context msg model =
  case msg of
    ReceivedMessage message ->
      -- This should probably be promoted to the Program module and we just receive a Continue message?
      if Message.is "_scenario" "state" message then
        case Message.decode Json.string message |> Result.withDefault "" of
          "CONTINUE" ->
            update actions context Continue model
          _ ->
            ( model, Cmd.none )
      else
        ( model
        , Cmd.batch
          [ actions.storeEffect message
          , actions.send Message.stepComplete
          ]
        )
    Continue ->
      case model.stepsToRun of
        [] -> 
          ( model, actions.finished )
        step :: remaining ->
          step context
            |> handleStepCommand actions { model | stepsToRun = remaining }


handleStepCommand : Actions msg programMsg -> Model model programMsg -> Step.Command programMsg -> ( Model model programMsg, Cmd msg)
handleStepCommand actions model command =
  case command of
    Step.SendMessage message ->
      ( model
      , actions.send <| Message.stepMessage message
      )
    Step.SendCommand cmd ->
      ( model
      , Cmd.batch
        [ Cmd.map actions.programMsg cmd
        , actions.send Step.programCommand
        ]
      )
    _ ->
      Debug.todo "Try to handle a command we can't yet handle!"
