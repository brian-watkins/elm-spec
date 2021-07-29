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
  | Effect Message
  | Continue
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
  }


type RunState model msg
  = Initializing (Initialize.Model model msg)
  | Ready
  | Exercising (Exercise.Model model msg)
  | Observing (Observe.Model model)


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

update : Config msg -> ExposedSetup model msg -> Dict String (ExposedSteps model msg) -> Dict String (ExposedExpectation model) -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config setupGenerator steps expectations msg model =
  case model of
    Waiting ->
      case msg of
        ReceivedMessage message ->
          if Message.is "_harness" "setup" message then
            Initialize.init (initializeActions config) setupGenerator message
              |> Tuple.mapFirst (\updated -> { programModel = updated.subject.model, effects = [], subject = updated.subject, state = Initializing updated })
              |> Tuple.mapFirst Running
          else
            -- Note that here we get _spec start message ... need to not send that for a harness ...
            ( model, Cmd.none )
        _ ->
          ( model, Cmd.none )
    Running runModel ->
      case msg of
        ProgramMsg programMsg ->
          runModel.subject.update programMsg runModel.programModel
            |> Tuple.mapFirst (\updated -> Running { runModel | programModel = updated })
            |> Tuple.mapSecond (\nextCommand ->
              Cmd.batch
              [ Cmd.map ProgramMsg nextCommand
              , config.send Step.programCommand
              ]
            )
        Effect message ->
          ( Running { runModel | effects = message :: runModel.effects }
          , Cmd.none
          )
        ReceivedMessage message ->
          case runModel.state of
            Initializing initializeModel ->
              Initialize.update (initializeActions config) (Initialize.ReceivedMessage message) initializeModel
                |> Tuple.mapFirst (\updated -> { runModel | state = Initializing updated })
                |> Tuple.mapFirst Running
            Ready ->
              if Message.is "_harness" "setup" message then
                update config setupGenerator steps expectations (ReceivedMessage message) Waiting
              else if Message.is "_harness" "observe" message then
                Observe.init (observeActions config) (expectationsRepo expectations) (Observe.defaultModel runModel.programModel runModel.effects) message
                  |> Tuple.mapFirst (\updated -> { runModel | state = Observing updated })
                  |> Tuple.mapFirst Running
              else if Message.is "_harness" "run" message then
                Exercise.init (exerciseActions config) (stepsRepo steps) Exercise.defaultModel message
                  |> Tuple.mapFirst (\updated -> { runModel | state = Exercising updated })
                  |> Tuple.mapFirst Running
              else
                ( model, Cmd.none )
            Exercising exerciseModel ->
              Exercise.update (exerciseActions config) (programContext runModel) (Exercise.ReceivedMessage message) exerciseModel
                |> Tuple.mapFirst (\updated -> { runModel | state = Exercising updated })
                |> Tuple.mapFirst Running
            Observing observeModel ->
              Observe.update (observeActions config) (Observe.ReceivedMessage message) observeModel
                |> Tuple.mapFirst (\updated -> { runModel | state = Observing updated })
                |> Tuple.mapFirst Running
        Continue ->
          case runModel.state of
            Exercising exerciseModel ->
              Exercise.update (exerciseActions config) (programContext runModel) Exercise.Continue exerciseModel
                |> Tuple.mapFirst (\updated -> { runModel | state = Exercising updated })
                |> Tuple.mapFirst Running
            _ ->
              ( model, Cmd.none )
        Finished ->
          case runModel.state of
            Ready ->
              ( model, Cmd.none )
            Initializing _ ->
              Exercise.initForInitialCommand (exerciseActions config) runModel.subject
                |> Tuple.mapFirst (\updated -> { runModel | state = Exercising updated })
                |> Tuple.mapFirst Running
            Exercising _ ->
              ( Running { runModel | state = Ready }
              , config.send Message.harnessActionComplete
              )
            Observing _ ->
              ( Running { runModel | state = Ready }
              , Cmd.none
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
  , finished = sendMessage Finished
  }


exerciseActions : Config msg -> Exercise.Actions (Msg msg) msg
exerciseActions config =
  { send = config.send
  , programMsg = ProgramMsg
  , storeEffect = \message -> sendMessage <| Effect message
  , continue = sendMessage Continue
  , finished = sendMessage Finished
  }

observeActions : Config msg -> Observe.Actions (Msg msg)
observeActions config =
  { send = config.send
  , finished = sendMessage Finished
  }


sendMessage : (Msg msg) -> Cmd (Msg msg)
sendMessage msg =
  Task.succeed never
    |> Task.perform (always msg)


subscriptions : Config msg -> Model model msg -> Sub (Msg msg)
subscriptions config model =
  case model of
    Running runModel ->
      Sub.batch
      [ runModel.subject.subscriptions runModel.programModel
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