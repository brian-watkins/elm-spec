module Spec exposing
  ( Spec
  , Model
  , Msg
  , Config
  , Expectation
  , given
  , when
  , it
  , suppose
  , update
  , view
  , init
  , subscriptions
  , program
  , browserProgram
  , expect
  )

import Spec.Observer as Observer exposing (Observer, Verdict)
import Spec.Observer.Report as Report
import Spec.Message as Message exposing (Message)
import Spec.Lifecycle as Lifecycle
import Spec.Subject as Subject exposing (Subject)
import Spec.Actual as Actual exposing (Actual)
import Task
import Json.Encode exposing (Value)
import Html exposing (Html)
import Dict exposing (Dict)
import Procedure.Program
import Procedure
import Procedure.Channel as Channel
import Procedure.Extra
import Browser


type Spec model msg =
  Spec
    { subject: Subject model msg
    , steps: List (Step model msg)
    , requirements: List (Requirement model msg)
    , scenarios: List (Subject model msg -> Spec model msg)
    }


type alias Step model msg =
  { run: Subject model msg -> Cmd (Msg msg)
  , condition: String
  }


type alias Expectation model msg =
  String -> Config msg -> Subject model msg -> Cmd (Msg msg)


type alias Requirement model msg =
  { description: String
  , expectation: Expectation model msg
  }


given : String -> Subject model msg -> Spec model msg
given description specSubject =
  Spec
    { subject = specSubject
    , steps = 
        [ { condition = formatGivenDescription description
          , run = \_ ->
            if specSubject.initialCommand == Cmd.none then
              goToNext
            else
              Cmd.map ProgramMsg specSubject.initialCommand
          }
        ]
    , requirements = []
    , scenarios = []
    }


when : String -> List (Subject model msg -> Message) -> Spec model msg -> Spec model msg
when condition messageSteps (Spec spec) =
  Spec
    { spec 
    | steps =
        messageSteps
          |> List.map (\f -> \specSubject ->
            f specSubject
              |> sendMessage
          )
          |> List.map (\step -> { run = step, condition = formatCondition condition })
          |> List.append spec.steps
    }


it : String -> Expectation model msg -> Spec model msg -> Spec model msg
it description expectation (Spec spec) =
  Spec 
    { spec 
    | requirements = spec.requirements ++
      [ { description = formatObservationDescription description
        , expectation = expectation
        }
      ]
    }


expect : Observer a -> Actual model a -> String -> Config msg -> Subject model msg -> Cmd (Msg msg)
expect observer actual description config subject =
  case actual of
    Actual.Model mapper ->
      Procedure.provide subject.model
        |> Procedure.map (mapper >> observer)
        |> Procedure.map (Observer.observation subject.conditions description)
        |> Procedure.run ProcedureMsg SendMessage
    Actual.Effects mapper ->
      Procedure.provide subject.effects
        |> Procedure.map (mapper >> observer)
        |> Procedure.map (Observer.observation subject.conditions description)
        |> Procedure.run ProcedureMsg SendMessage
    Actual.Inquiry message mapper ->
      Channel.open (\key -> config.send <| Observer.inquiry key message)
        |> Channel.connect config.listen
        |> Channel.filter (\key data -> filterForInquiryResult key data)
        |> Channel.acceptOne
        |> Procedure.map (\inquiry ->
          Message.decode Observer.inquiryDecoder inquiry
            |> Maybe.map .message
            |> Maybe.map (mapper >> observer)
            |> Maybe.withDefault (Observer.Reject <| Report.note "Unable to decode inquiry result!")
            |> Observer.observation subject.conditions description
        )
        |> Procedure.run ProcedureMsg SendMessage


filterForInquiryResult : String -> Message -> Bool
filterForInquiryResult key message =
  if Message.is "_observer" "inquiryResult" message then
    Message.decode Observer.inquiryDecoder message
      |> Maybe.map .key
      |> Maybe.map (\actual -> actual == key)
      |> Maybe.withDefault False
  else
    False


suppose : (Subject model msg -> Spec model msg) -> Spec model msg -> Spec model msg
suppose generator (Spec spec) =
  Spec
    { spec | scenarios = generator :: spec.scenarios }


sendMessage : Message -> Cmd (Msg msg)
sendMessage message =
  Task.succeed message
    |> Task.perform SendMessage


goToNext : Cmd (Msg msg)
goToNext =
  sendLifecycle Lifecycle.Next


sendLifecycle : Lifecycle.Msg -> Cmd (Msg msg)
sendLifecycle lifecycleMsg =
  Task.succeed never
    |> Task.perform (always <| Lifecycle lifecycleMsg)


formatGivenDescription : String -> String
formatGivenDescription description =
  "Given " ++ description


formatCondition : String -> String
formatCondition condition =
  "When " ++ condition


formatObservationDescription : String -> String
formatObservationDescription description =
  "It " ++ description



---- Program


type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , outlet: Message -> Cmd msg
  , listen: (Message -> (Msg msg)) -> Sub (Msg msg)
  }


type Msg msg
  = ProcedureMsg (Procedure.Program.Msg (Msg msg))
  | ProgramMsg msg
  | SendMessage Message
  | ReceivedEffect Message
  | Lifecycle Lifecycle.Msg


type alias Model model msg =
  { specs: List (Spec model msg)
  , state: State model msg
  , procedureModel: Procedure.Program.Model (Msg msg)
  }


type State model msg
  = Ready
  | Configure (Spec model msg)
  | Exercise (Spec model msg) (ExerciseModel model msg)
  | Observe (Spec model msg) (ObserveModel model msg)
  | Abort


type alias StateModel model a =
  { a
  | conditionsApplied: List String
  , model: model
  , effects: List Message
  }


type alias ExerciseModel model msg =
  StateModel model
    { steps: List (Step model msg)
    }


type alias ObserveModel model msg =
  StateModel model
    { requirements: (List (Requirement model msg))
    }


view : Model model msg -> Html (Msg msg)
view model =
  case model.state of
    Exercise (Spec spec) exerciseModel ->
      spec.subject.view exerciseModel.model
        |> Html.map ProgramMsg
    Observe (Spec spec) observeModel ->
      spec.subject.view observeModel.model
        |> Html.map ProgramMsg
    _ ->
      Html.text ""


receiveLifecycleMessages : Config msg -> Cmd (Msg msg)
receiveLifecycleMessages config =
  Channel.join config.listen
    |> Channel.filter (\_ message ->
      Lifecycle.isLifecycleMessage message
    )
    |> Channel.accept
    |> Procedure.map Lifecycle.toMsg
    |> Procedure.andThen Procedure.Extra.bump
    |> Procedure.run ProcedureMsg Lifecycle


receiveEffectMessages : Config msg -> Cmd (Msg msg)
receiveEffectMessages config =
  Channel.join config.listen
    |> Channel.filter (\_ message ->
      message.home /= "_spec" && message.home /= "_observer"
    )
    |> Channel.accept
    |> Procedure.run ProcedureMsg ReceivedEffect


update : Config msg -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config msg model =
  case msg of
    ProcedureMsg procMsg ->
      Procedure.Program.update procMsg model.procedureModel
        |> Tuple.mapFirst (\updated -> { model | procedureModel = updated })
    ReceivedEffect message ->
      case model.state of
        Exercise spec exerciseModel ->
          ( { model | state = Exercise spec { exerciseModel | effects = message :: exerciseModel.effects } }
          , config.send Lifecycle.stepComplete
          )
        _ ->
          ( model, Cmd.none )
    SendMessage message ->
      ( model, config.send message )
    ProgramMsg programMsg ->
      case model.state of
        Exercise (Spec spec) exerciseModel ->
          spec.subject.update config.outlet programMsg exerciseModel.model
            |> Tuple.mapFirst (\updated -> { model | state = Exercise (Spec spec) { exerciseModel | model = updated } })
            |> Tuple.mapSecond (\nextCommand ->
              if nextCommand == Cmd.none then
                config.send Lifecycle.stepComplete
              else
                Cmd.map ProgramMsg nextCommand
            )
        _ -> 
          ( model, Cmd.none )
    Lifecycle lifecycleMsg ->
      lifecycleUpdate config lifecycleMsg model


lifecycleUpdate : Config msg -> Lifecycle.Msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
lifecycleUpdate config msg model =
  case msg of
    Lifecycle.Next ->
      case model.state of
        Ready ->
          case model.specs of
            [] ->
              ( model, config.send Lifecycle.specComplete )
            (Spec spec) :: remaining ->
              ( { model | specs = remaining, state = Configure (Spec spec) }
              , Cmd.batch
                [ config.send Lifecycle.configureComplete
                , Cmd.batch <| List.map config.send spec.subject.configureEnvironment
                ]
              )
        Configure spec ->
          ( { model | state = toExercise spec }
          , goToNext
          )
        Exercise spec exerciseModel ->
          case exerciseModel.steps of
            [] ->
              ( { model | state = toObserve spec exerciseModel }
              , goToNext
              )
            step :: remaining ->
              ( { model | state = Exercise spec
                  { exerciseModel
                  | steps = remaining
                  , conditionsApplied = exerciseModel.conditionsApplied ++ [ step.condition ]
                  }
                }
              , subjectFrom spec
                  |> currentSubject exerciseModel
                  |> step.run
              )
        Observe spec observeModel ->
          case observeModel.requirements of
            [] ->
              ( { model
                | specs = List.append (scenarioSpecs spec observeModel) model.specs 
                , state = Ready
                }
              , goToNext
              )
            requirement :: remaining ->
              ( { model | state = Observe spec { observeModel | requirements = remaining } }
              , subjectFrom spec
                  |> currentSubject observeModel
                  |> requirement.expectation requirement.description config
              )
        Abort ->
          ( model, config.send Lifecycle.specComplete )
    Lifecycle.Abort report ->
      case model.state of
        Exercise spec exerciseModel ->
          ( { model | state = Abort }
          , Observer.Reject report
              |> Observer.observation exerciseModel.conditionsApplied "A spec step failed"
              |> config.send
          )
        _ ->
          ( model, Cmd.none )


toExercise : Spec model msg -> State model msg
toExercise (Spec spec) =
  Exercise (Spec spec)
    { conditionsApplied = spec.subject.conditions
    , model = spec.subject.model
    , effects = spec.subject.effects
    , steps = spec.steps
    }


toObserve : Spec model msg -> ExerciseModel model msg -> State model msg
toObserve (Spec spec) exerciseModel =
  Observe (Spec spec)
    { conditionsApplied = exerciseModel.conditionsApplied
    , model = exerciseModel.model
    , effects = exerciseModel.effects
    , requirements = spec.requirements
    }


scenarioSpecs : Spec model msg -> ObserveModel model msg -> List (Spec model msg)
scenarioSpecs (Spec spec) observeModel =
  spec.scenarios
    |> List.map (\generator ->
      currentSubject observeModel spec.subject
        |> generator
    )


currentSubject : StateModel model a -> Subject model msg -> Subject model msg
currentSubject state original =
  { original
  | model = state.model
  , effects = state.effects
  , conditions = state.conditionsApplied
  }


subscriptions : Config msg -> Model model msg -> Sub (Msg msg)
subscriptions config model =
  case model.state of
    Exercise (Spec spec) exerciseModel ->
      Sub.batch
      [ Sub.map ProgramMsg <| Subject.subscriptions spec.subject
      , Procedure.Program.subscriptions model.procedureModel
      ]
    _ ->
      Procedure.Program.subscriptions model.procedureModel
  

init : Config msg -> List (Spec model msg) -> () -> ( Model model msg, Cmd (Msg msg) )
init config specs _ =
  ( { specs = specs, state = Ready, procedureModel = Procedure.Program.init }
  , Cmd.batch
    [ receiveLifecycleMessages config
    , receiveEffectMessages config
    ]
  )


program : Config msg -> List (Spec model msg) -> Program () (Model model msg) (Msg msg)
program config specs =
  Platform.worker
    { init = init config specs
    , update = update config
    , subscriptions = subscriptions config
    }


browserProgram : Config msg -> List (Spec model msg) -> Program () (Model model msg) (Msg msg)
browserProgram config specs =
  Browser.element
    { init = init config specs
    , view = view
    , update = update config
    , subscriptions = subscriptions config
    }


-- Helpers

subjectFrom : Spec model msg -> Subject model msg
subjectFrom (Spec spec) =
  spec.subject