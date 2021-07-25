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
import Spec.Step.Context as Context
import Spec.Step.Command as Step
import Spec.Step.Message as Message
import Json.Decode as Json
import Spec.Setup.Internal exposing (Subject)


type alias Model model programMsg =
  { programModel: model
  , effects: List Message 
  , stepsToRun: List (Step model programMsg)
  }


defaultModel : model -> List Message -> Model model programMsg
defaultModel programModel effects =
  { programModel = programModel
  , effects = effects
  , stepsToRun = []
  }


type Msg programMsg
  = Continue
  | ReceivedMessage Message


type alias Actions msg programMsg =
  { send : Message -> Cmd msg
  , programMsg : programMsg -> msg
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
initForInitialCommand actions subject =
  let
    model = defaultModel subject.model []
  in
  ( { model | stepsToRun = [ \_ -> Step.sendToProgram subject.initialCommand ] }
  , actions.continue
  )


update : Actions msg programMsg -> Msg programMsg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
update actions msg model =
  case msg of
    ReceivedMessage message ->
      if Message.is "_scenario" "state" message then
        case Message.decode Json.string message |> Result.withDefault "" of
          "CONTINUE" ->
            update actions Continue model
          _ ->
            ( model, Cmd.none )
      else
        ( { model | effects = message :: model.effects }
        , actions.send Message.stepComplete
        )
    Continue ->
      case model.stepsToRun of
        [] -> 
          ( model, actions.finished )
        step :: remaining ->
          Context.for model.programModel
            |> Context.withEffects model.effects
            |> step
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
