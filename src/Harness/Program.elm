module Harness.Program exposing
  ( init
  , Msg
  , Model
  , Flags
  , Config
  , Exports
  , update
  , view
  , subscriptions
  , onUrlChange
  , onUrlRequest
  )

import Spec.Message exposing (Message)
import Browser exposing (UrlRequest, Document)
import Spec.Step.Command as Step
import Spec.Observer.Internal exposing (Judgment(..))
import Spec.Scenario.Message as Message
import Spec.Step.Message as Message
import Spec.Message as Message
import Spec.Observer.Message as Message
import Spec.Report as Report exposing (Report)
import Harness.Message as Message
import Harness.Initialize as Initialize
import Harness.Observe as Observe
import Harness.Exercise as Exercise
import Harness.Subject as Subject
import Harness.Types exposing (..)
import Url exposing (Url)
import Html
import Task
import Dict exposing (Dict)
import Browser.Navigation as Navigation
import Spec.Version as Version exposing (Version)


type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


type alias Exports model msg =
  { setups: Dict String (ExposedSetup model msg)
  , steps: Dict String (ExposedSteps model msg)
  , expectations: Dict String (ExposedExpectation model)
  }


type Msg msg
  = SubjectMsg (Subject.Msg msg)
  | InitializeMsg Initialize.Msg
  | RunInitialCommand
  | ExerciseMsg (Exercise.Msg msg)
  | ObserveMsg Observe.Msg
  | Finished
  | ReceivedMessage Message
  | Error Report


type Model model msg
  = Waiting WaitingModel
  | Running (RunModel model msg)
  | Failed Report


type alias WaitingModel =
  { key: Maybe Navigation.Key
  }


type alias RunModel model msg =
  { state: RunState model msg
  , subjectModel: Subject.Model model msg 
  , initializeModel: Initialize.Model model msg
  , exerciseModel: Exercise.Model model msg
  , observeModel: Observe.Model model
  , key: Maybe Navigation.Key
  }


generateRunModel : Maybe Navigation.Key -> Initialize.Model model msg -> RunModel model msg
generateRunModel maybeKey initializeModel =
  let
    subject = Initialize.harnessSubject initializeModel
  in
    { state = Initializing
    , subjectModel = Subject.defaultModel subject
    , initializeModel = initializeModel
    , exerciseModel = Exercise.defaultModel
    , observeModel = Observe.defaultModel
    , key = maybeKey
    }


type RunState model msg
  = Initializing
  | Ready
  | Exercising
  | Observing


type alias Flags =
  { version: Version
  }


init : Version -> Flags -> Maybe Navigation.Key -> ( Model model msg, Cmd (Msg msg) )
init requiredVersion flags maybeKey =
  if Version.isOk { required = requiredVersion, actual = flags.version } then
    ( Waiting { key = maybeKey }, Cmd.none )
  else
    ( Failed <| Version.error { required = requiredVersion, actual = flags.version }
    , Cmd.none
    )


waiting : RunModel model msg -> Model model msg
waiting runModel =
  Waiting { key = runModel.key }


view : Model model msg -> Document (Msg msg)
view model =
  case model of
    Waiting _ ->
      { title = "Harness Program"
      , body = [ Html.text "" ]
      }
    Running runModel ->
      Subject.view SubjectMsg runModel.subjectModel
    Failed _ ->
      { title = "Harness Program"
      , body = [ Html.text "" ]
      }


update : Config msg -> Exports model msg -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config exports msg model =
  case ( model, msg ) of
    ( Waiting waitingModel, ReceivedMessage message ) ->
      if Message.is "_harness" "start" message then
        case Initialize.generateSubject (setupsRepo exports.setups) waitingModel.key message of
          Ok subject ->
            Initialize.init (initializeActions config) subject
              |> Tuple.mapFirst (generateRunModel waitingModel.key)
              |> Tuple.mapFirst Running
          Err report ->
            ( model
            , abortWith config report
            )
      else
        ( model
        , abortWith config <| unknownMessageReport message
        )

    ( Running runModel, ReceivedMessage message ) ->
      if Message.is "_harness" "start" message then
        update config exports (ReceivedMessage message) (waiting runModel)
      else if Message.is "_harness" "observe" message then
        case Observe.generateModel (expectationsRepo exports.expectations) message of
          Ok observeModel ->
            Observe.init (observeActions config) observeModel
              |> Tuple.mapFirst (\updated -> { runModel | state = Observing, observeModel = updated })
              |> Tuple.mapFirst Running
          Err report ->
            ( waiting runModel
            , abortWith config report
            )
      else if Message.is "_harness" "run" message then
        case Exercise.generateSteps (stepsRepo exports.steps) message of
          Ok steps ->
            Exercise.init (exerciseActions config) steps
              |> Tuple.mapFirst (\updated -> { runModel | state = Exercising, exerciseModel = updated })
              |> Tuple.mapFirst Running
          Err report ->
            ( waiting runModel
            , abortWith config report
            )
      else if Message.is "_harness" "wait" message then
        Exercise.wait (exerciseActions config)
          |> Tuple.mapFirst (\updated -> { runModel | state = Exercising, exerciseModel = updated })
          |> Tuple.mapFirst Running
      else
        -- Note that we are getting other messages too if things are triggered by a port from the JS side ...
        ( model, Cmd.none )

    ( Running runModel, SubjectMsg subjectMsg ) ->
      if runModel.state == Initializing then
        ( model, config.send Message.stepComplete )
      else
        Subject.update (subjectActions config) subjectMsg runModel.subjectModel
          |> Tuple.mapFirst (\updated -> Running { runModel | subjectModel = updated })

    ( Running runModel, InitializeMsg initializeMsg ) ->
      Initialize.update (initializeActions config) initializeMsg runModel.initializeModel
        |> Tuple.mapFirst (\updated -> { runModel | initializeModel = updated })
        |> Tuple.mapFirst Running

    ( Running runModel, ExerciseMsg exerciseMsg ) ->
      Exercise.update (exerciseActions config) (Subject.programContext runModel.subjectModel) exerciseMsg runModel.exerciseModel
        |> Tuple.mapFirst (\updated -> { runModel | exerciseModel = updated })
        |> Tuple.mapFirst Running

    ( Running runModel, ObserveMsg observeMsg ) ->
      Observe.update (observeActions config) (Subject.programContext runModel.subjectModel) observeMsg runModel.observeModel
        |> Tuple.mapFirst (\updated -> { runModel | state = Observing, observeModel = updated })
        |> Tuple.mapFirst Running

    ( Running runModel, RunInitialCommand ) ->
      Exercise.initForInitialCommand (exerciseActions config) (Subject.initialCommand runModel.subjectModel)
        |> Tuple.mapFirst (\updated -> { runModel | state = Exercising, exerciseModel = updated })
        |> Tuple.mapFirst Running

    ( Running runModel, Finished ) ->
      ( Running { runModel | state = Ready }
      , config.send Message.harnessActionComplete
      )

    ( Running runModel, Error report ) ->
      ( waiting runModel
      , abortWith config report
      )

    ( Failed report, _ ) ->
      ( model
      , abortWith config report
      )

    _ ->
      ( model, Cmd.none )


abortWith : Config msg -> Report -> Cmd (Msg msg)
abortWith config report =
  Message.abortHarness report
    |> config.send


unknownMessageReport : Message -> Report
unknownMessageReport message =
  "Unknown message received while waiting to start a scenario: " ++ message.home ++ "/" ++ message.name
    |> Report.note


setupsRepo : Dict String (ExposedSetup model msg) -> Initialize.ExposedSetupRepository model msg
setupsRepo setups =
  { get = \name ->
      Dict.get name setups
  }


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


subjectActions : Config msg -> Subject.Actions (Msg msg) msg
subjectActions config =
  { send = config.send
  , sendCommand = sendCommand config
  , listen = \messageHandler ->
      config.listen (\message ->
        messageHandler message
          |> SubjectMsg
      )
  , sendToSelf = SubjectMsg
  , abort = sendMessage << Error
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
  , storeEffect = \message -> sendMessage <| SubjectMsg <| Subject.storeEffect message
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
  , sendToSelf = \msg -> sendMessage (ObserveMsg msg)
  }


sendCommand : Config msg -> Cmd msg -> Cmd (Msg msg)
sendCommand config cmd =
  Cmd.batch
    [ Cmd.map (SubjectMsg << Subject.programMsgTagger) cmd
    , config.send Step.programCommand
    ]


sendMessage : (Msg msg) -> Cmd (Msg msg)
sendMessage msg =
  Task.succeed never
    |> Task.perform (always msg)


subscriptions : Config msg -> Model model msg -> Sub (Msg msg)
subscriptions config model =
  case model of
    Waiting _ ->
      config.listen ReceivedMessage
    Failed _ ->
      config.listen ReceivedMessage
    Running runModel ->
      case runModel.state of
        Ready ->
          Sub.batch
          [ config.listen ReceivedMessage
          , Subject.subscriptions (subjectActions config) runModel.subjectModel
          ]
        Initializing ->
          Initialize.subscriptions (initializeActions config) runModel.initializeModel
        Exercising ->
          Sub.batch
          [ Exercise.subscriptions (exerciseActions config) runModel.exerciseModel
          , Subject.subscriptions (subjectActions config) runModel.subjectModel
          ]
        Observing ->
          Observe.subscriptions (observeActions config) runModel.observeModel


onUrlRequest : UrlRequest -> (Msg msg)
onUrlRequest =
  SubjectMsg << Subject.urlRequestHandler


onUrlChange : Url -> (Msg msg)
onUrlChange =
  SubjectMsg << Subject.urlChangeHandler