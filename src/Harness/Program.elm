module Harness.Program exposing
  ( init
  , Msg
  , Model
  , Flags
  , Config
  , update
  , view
  , subscriptions
  , onUrlChange
  , onUrlRequest
  )

import Spec.Message exposing (Message)
import Browser exposing (UrlRequest, Document)
import Spec.Setup.Internal as Setup exposing (Subject)
import Spec.Step.Command as Step
import Spec.Observer.Internal exposing (Judgment(..))
import Spec.Scenario.Message as Message
import Spec.Message as Message
import Spec.Observer.Message as Message
import Harness.Message as Message
import Harness.Initialize as Initialize
import Harness.Observe as Observe
import Harness.Exercise as Exercise
import Harness.Types exposing (..)
import Url exposing (Url)
import Html exposing (Html)
import Dict exposing (Dict)
import Task
import Spec.Step.Context as Context exposing (Context)


type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


type Msg msg
  = ProgramMsg msg
  | StoreEffect Message
  | InitializeMsg Initialize.Msg
  | RunInitialCommand
  | ExerciseMsg (Exercise.Msg msg)
  | ObserveMsg Observe.Msg
  | Finished
  | ReceivedMessage Message
  | OnUrlRequest UrlRequest
  | OnUrlChange Url


type Model model msg
  = Waiting
  | Running (RunModel model msg)


type alias RunModel model msg =
  { programModel: model
  , effects: List Message
  , subject: Subject model msg
  , state: RunState model msg
  , initializeModel: Initialize.Model model msg
  , exerciseModel: Exercise.Model model msg
  , observeModel: Observe.Model model
  }


type RunState model msg
  = Initializing
  | Ready
  | Exercising
  | Observing


type alias Flags =
  { }


init : ( Model model msg, Cmd (Msg msg) )
init =
  ( Waiting, Cmd.none )


view : Model model msg -> Document (Msg msg)
view model =
  case model of
    Waiting ->
      { title = "Harness Program"
      , body = [ fakeBody ]
      }
    Running runModel ->
      programView runModel.subject runModel.programModel


programView : (Subject model msg) -> model -> Document (Msg msg)
programView subject model =
  case subject.view of
    Setup.Element v ->
      { title = "Harness Element Program"
      , body = [ v model |> Html.map ProgramMsg ]
      }
    Setup.Document v ->
      let
        doc = v model
      in
        { title = doc.title
        , body =
            doc.body
              |> List.map (Html.map ProgramMsg)
        }


fakeBody : Html (Msg msg)
fakeBody =
  Html.div []
    [ Html.text "Waiting ..."
    ]


update : Config msg -> ExposedSetup model msg -> Dict String (ExposedSteps model msg) -> Dict String (ExposedExpectation model) -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config setupGenerator steps expectations msg model =
  case ( model, msg ) of
    ( Waiting, ReceivedMessage message ) ->
      if Message.is "_harness" "setup" message then
        Initialize.init (initializeActions config) setupGenerator message
          |> Tuple.mapFirst (\updated -> { programModel = updated.subject.model, effects = [], subject = updated.subject, state = Initializing, initializeModel = updated, exerciseModel = Exercise.defaultModel, observeModel = Observe.defaultModel })
          |> Tuple.mapFirst Running
      else
        -- Note that here we could get _spec start message ... need to not send that for a harness ...
        -- And we want an error here if you try to run steps or observe without having called setup first
        ( model, Cmd.none )
    
    ( Running runModel, ProgramMsg programMsg ) ->
      runModel.subject.update programMsg runModel.programModel
        |> Tuple.mapFirst (\updated -> Running { runModel | programModel = updated })
        |> Tuple.mapSecond (sendCommand config)
    
    ( Running _, OnUrlChange _ ) ->
      ( model, Cmd.none )
    
    ( Running _, OnUrlRequest _ ) ->
      ( model, Cmd.none )
    
    ( Running runModel, StoreEffect message ) ->
      ( Running { runModel | effects = message :: runModel.effects }
      , Cmd.none
      )
    
    ( Running runModel, InitializeMsg initializeMsg ) ->
      Initialize.update (initializeActions config) initializeMsg runModel.initializeModel
        |> Tuple.mapFirst (\updated -> { runModel | initializeModel = updated })
        |> Tuple.mapFirst Running
    
    ( Running runModel, ExerciseMsg exerciseMsg ) ->
      Exercise.update (exerciseActions config) (programContext runModel) exerciseMsg runModel.exerciseModel
        |> Tuple.mapFirst (\updated -> { runModel | exerciseModel = updated })
        |> Tuple.mapFirst Running
    
    ( Running runModel, ObserveMsg observeMsg ) ->
      Observe.update (observeActions config) observeMsg runModel.observeModel
        |> Tuple.mapFirst (\updated -> { runModel | state = Observing, observeModel = updated })
        |> Tuple.mapFirst Running
    
    ( Running runModel, ReceivedMessage message ) ->
      if Message.is "_harness" "setup" message then
        update config setupGenerator steps expectations (ReceivedMessage message) Waiting
      else if Message.is "_harness" "observe" message then
        Observe.init (observeActions config) (expectationsRepo expectations) (programContext runModel) Observe.defaultModel message
          |> Tuple.mapFirst (\updated -> { runModel | state = Observing, observeModel = updated })
          |> Tuple.mapFirst Running
      else if Message.is "_harness" "run" message then
        Exercise.init (exerciseActions config) (stepsRepo steps) Exercise.defaultModel message
          |> Tuple.mapFirst (\updated -> { runModel | state = Exercising, exerciseModel = updated })
          |> Tuple.mapFirst Running
      else
        -- Here we are receiving the start scenario message, which we should stop I think ...
        ( model, Cmd.none )
    
    ( Running runModel, RunInitialCommand ) ->
      Exercise.initForInitialCommand (exerciseActions config) runModel.subject
        |> Tuple.mapFirst (\updated -> { runModel | state = Exercising, exerciseModel = updated })
        |> Tuple.mapFirst Running
    
    ( Running runModel, Finished ) ->
      ( Running { runModel | state = Ready }
      , config.send Message.harnessActionComplete
      )
    
    _ ->
      ( model, Cmd.none )


programContext : RunModel model msg -> Context model
programContext model =
  Context.for model.programModel
    |> Context.withEffects model.effects


expectationsRepo : Dict String (ExposedExpectation model) -> Observe.ExposedExpectationRepository model
expectationsRepo expectations =
  { get = \name ->
      Dict.get name expectations
  }


stepsRepo : Dict String (ExposedSteps model msg) -> Exercise.ExposedStepsRepository model msg
stepsRepo steps =
  { get = \name ->
      Dict.get name steps
  }


initializeActions : Config msg -> Initialize.Actions (Msg msg)
initializeActions config =
  { send = config.send
  , finished = sendMessage RunInitialCommand
  , listen = \messageHandler ->
      config.listen (\message ->
        messageHandler message
          |> InitializeMsg
      )
  }


exerciseActions : Config msg -> Exercise.Actions (Msg msg) msg
exerciseActions config =
  { send = config.send
  , sendProgramCommand = sendCommand config
  , storeEffect = \message -> sendMessage <| StoreEffect message
  , sendToSelf = \msg -> sendMessage (ExerciseMsg msg)
  , finished = sendMessage Finished
  , listen = \messageHandler ->
      config.listen (\message ->
        messageHandler message
          |> ExerciseMsg
      )
  }

observeActions : Config msg -> Observe.Actions (Msg msg)
observeActions config =
  { send = config.send
  , finished = sendMessage Finished
  , listen = \messageHandler ->
      config.listen (\message ->
        messageHandler message
          |> ObserveMsg
      )
  }


sendCommand : Config msg -> Cmd msg -> Cmd (Msg msg)
sendCommand config cmd =
  Cmd.batch
    [ Cmd.map ProgramMsg cmd
    , config.send Step.programCommand
    ]


sendMessage : (Msg msg) -> Cmd (Msg msg)
sendMessage msg =
  Task.succeed never
    |> Task.perform (always msg)


subscriptions : Config msg -> Model model msg -> Sub (Msg msg)
subscriptions config model =
  case model of
    Waiting ->
      config.listen ReceivedMessage
    Running runModel ->
      case runModel.state of
        Ready ->
          Sub.batch
          [ config.listen ReceivedMessage
          , runModel.subject.subscriptions runModel.programModel
              |> Sub.map ProgramMsg
          ]
        Initializing ->
          Initialize.subscriptions (initializeActions config) runModel.initializeModel
        Exercising ->
          Sub.batch
          [ Exercise.subscriptions (exerciseActions config) runModel.exerciseModel
          , runModel.subject.subscriptions runModel.programModel
              |> Sub.map ProgramMsg
          ]
        Observing ->
          Observe.subscriptions (observeActions config) runModel.observeModel


onUrlRequest : UrlRequest -> (Msg msg)
onUrlRequest =
  OnUrlRequest


onUrlChange : Url -> (Msg msg)
onUrlChange =
  OnUrlChange