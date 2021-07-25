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
import Spec.Setup exposing (Setup)
import Harness.Observe as Observe
import Harness.Exercise as Exercise
import Harness.Types exposing (..)
import Url exposing (Url)
import Html exposing (Html)
import Spec.Setup.Internal exposing (initializeSubject)
import Dict exposing (Dict)
import Task
import Json.Decode as Json

type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


type Msg msg
  = ProgramMsg msg
  | Continue
  | Finished
  | ReceivedMessage Message
  | OnUrlRequest UrlRequest
  | OnUrlChange Url


type Model model msg
  = Waiting
  | Setup (Subject model msg)
  | Ready (Subject model msg) (HarnessModel model)
  | Exercising (Subject model msg) (Exercise.Model model msg)
  | Observing (Subject model msg) (Observe.Model model)

type alias HarnessModel model =
  { programModel: model
  , effects: List Message
  }

type alias Flags =
  { }


init : Setup model msg -> ( Model model msg, Cmd (Msg msg) )
init setup =
  let
    -- probably don't want to do this here but once we get the start message we should initialize the harness
    -- subject. BUT would we have multiple setups in the same harness? It might fire a command though ...
    -- It might not be that we have multiple setup functions ... but it might be that we have one function
    -- that takes an argument resulting in different setups. But in any case, if we want to be able to
    -- run multiple times, we can't do this (only) in the init. But fine for now.
    maybeSubject = initializeSubject setup Nothing
  in
    case maybeSubject of
      Ok subject ->
        ( Setup subject, Cmd.none )
      Err _ ->
        Debug.todo "Could not initialize subject!"


view : Model model msg -> Document (Msg msg)
view model =
  case model of
    Ready subject harnessModel ->
      programView subject harnessModel.programModel
    Observing subject observeModel ->
      programView subject observeModel.programModel
    Exercising subject exerciseModel ->
      programView subject exerciseModel.programModel
    _ ->
      { title = "Harness Program"
      , body = [ fakeBody ]
      }


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


-- Maybe we need to have different subscriptions, based on the model
-- so we can just send the received message directly to the state handler? 
-- Then our Msg type is more about ObserveMsg, ExerciseMsg, etc
-- Ultimately Setup needs to run some configure step, but then it's just like the Exercise state
-- where the step is just to run the initial command

-- For Setup, several things need to happen:
-- 1. Create the subject (at least once, but we could do it every time)
-- 2. Reset the elm context (and wait for any animation tasks to finish)
-- 3. Run any configuration steps (no tests for this yet)
-- 4. Run the initial command (in the right way that triggers a view update, but no tests with an initial command yet)

update : Config msg -> Dict String (ExposedSteps model msg) -> Dict String (ExposedExpectation model) -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config steps expectations msg model =
  case model of
    Setup subject ->
      case msg of
        ReceivedMessage message ->
          if Message.is "_harness" "setup" message then
            ( model, config.send Message.startScenario )
          else if Message.is "_scenario" "state" message then
            case Message.decode Json.string message |> Result.withDefault "" of
              "CONTINUE" ->
                Exercise.initForInitialCommand (exerciseActions config) subject
                  |> Tuple.mapFirst (Exercising subject)
              _ ->
                Debug.todo "Unexpected scenario state message in Harness Program!"
          else
            ( model, Cmd.none )
        _ ->
          ( model, Cmd.none )
    Ready subject harnessModel ->
      case msg of
        ReceivedMessage message ->
          if Message.is "_harness" "setup" message then
            update config steps expectations (ReceivedMessage message) (Setup subject)
          else if Message.is "_harness" "observe" message then
            Observe.init (observeActions config) (expectationsRepo expectations) (Observe.defaultModel harnessModel.programModel harnessModel.effects) message
              |> Tuple.mapFirst (Observing subject)
          else if Message.is "_harness" "run" message then
            Exercise.init (exerciseActions config) (stepsRepo steps) (Exercise.defaultModel harnessModel.programModel harnessModel.effects) message
              |> Tuple.mapFirst (Exercising subject)
          else
            ( model, Cmd.none )
        ProgramMsg programMsg ->
          subject.update programMsg harnessModel.programModel
            |> Tuple.mapFirst (\updated -> Ready subject { harnessModel | programModel = updated })
            |> Tuple.mapSecond (\nextCommand ->
              Cmd.batch
              [ Cmd.map ProgramMsg nextCommand
              , config.send Step.programCommand
              ]
            )
        _ ->
          ( model, Cmd.none )
    Exercising subject exerciseModel ->
      case msg of
        ReceivedMessage message ->
          Exercise.update (exerciseActions config) (Exercise.ReceivedMessage message) exerciseModel
            |> Tuple.mapFirst (Exercising subject)
        Continue ->
          Exercise.update (exerciseActions config) Exercise.Continue exerciseModel
            |> Tuple.mapFirst (Exercising subject)
        Finished ->
          ( Ready subject { programModel = exerciseModel.programModel, effects = exerciseModel.effects }
          , config.send Message.harnessActionComplete
          )
        ProgramMsg programMsg ->
          subject.update programMsg exerciseModel.programModel
            |> Tuple.mapFirst (\updated -> Exercising subject { exerciseModel | programModel = updated })
            |> Tuple.mapSecond (\nextCommand ->
              Cmd.batch
              [ Cmd.map ProgramMsg nextCommand
              , config.send Step.programCommand
              ]
            )
        _ ->
          ( model, Cmd.none )
    Observing subject observeModel ->
      case msg of
        ReceivedMessage message ->
          Observe.update (observeActions config) (Observe.ReceivedMessage message) observeModel
            |> Tuple.mapFirst (Observing subject)
        Finished ->
          ( Ready subject { programModel = observeModel.programModel, effects = observeModel.effects }
          , Cmd.none
          )
        _ ->
          ( model, Cmd.none )
    Waiting ->
      ( model, Cmd.none )



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


exerciseActions : Config msg -> Exercise.Actions (Msg msg) msg
exerciseActions config =
  { send = config.send
  , programMsg = ProgramMsg
  , continue =
      Task.succeed never
        |> Task.perform (always Continue)
  , finished =
      Task.succeed never
        |> Task.perform (always Finished)
  }

observeActions : Config msg -> Observe.Actions (Msg msg)
observeActions config =
  { send = config.send
  , finished =
      Task.succeed never
        |> Task.perform (always Finished)
  }


subscriptions : Config msg -> Model model msg -> Sub (Msg msg)
subscriptions config model =
  case model of
    Ready subject harnessModel ->
      Sub.batch
      [ subject.subscriptions harnessModel.programModel
          |> Sub.map ProgramMsg
      , config.listen ReceivedMessage
      ]
    Exercising subject exerciseModel ->
      Sub.batch
      [ subject.subscriptions exerciseModel.programModel
          |> Sub.map ProgramMsg
      , config.listen ReceivedMessage
      ]
    _ ->
      config.listen ReceivedMessage


onUrlRequest : UrlRequest -> (Msg msg)
onUrlRequest =
  OnUrlRequest


onUrlChange : Url -> (Msg msg)
onUrlChange =
  OnUrlChange