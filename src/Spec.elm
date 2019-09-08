module Spec exposing
  ( Spec, Scenario, Expectation
  , describe, scenario
  , when, it, expect
  , Model, Msg, Config
  , update, view, init, subscriptions
  , program, browserProgram
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
    (List (Scenario model msg))


type Scenario model msg =
  Scenario
    { subject: Subject model msg
    , steps: List (Step model msg)
    , requirements: List (Requirement model msg)
    }


type alias Step model msg =
  { run: Subject model msg -> Cmd (Msg msg)
  , condition: String
  }


type Expectation model msg =
  Expectation
    ( String -> Config msg -> Subject model msg -> Cmd (Msg msg) )


type alias Requirement model msg =
  { description: String
  , expectation: Expectation model msg
  }


describe : String -> List (Scenario model msg) -> Spec model msg
describe description scenarios =
  scenarios
    |> List.map (\(Scenario scenarioData) ->
      let
          subject = scenarioData.subject
      in
        Scenario
          { scenarioData
          | subject = { subject | conditions = [ formatSpecDescription description ] }
          }
    )
    |> Spec


scenario : String -> Subject model msg -> Scenario model msg
scenario description specSubject =
  Scenario
    { subject = specSubject
    , steps = 
        [ { condition = formatScenarioDescription description
          , run = \_ ->
            if specSubject.initialCommand == Cmd.none then
              goToNext
            else
              Cmd.map ProgramMsg specSubject.initialCommand
          }
        ]
    , requirements = []
    }


when : String -> List (Subject model msg -> Message) -> Scenario model msg -> Scenario model msg
when condition messageSteps (Scenario scenarioData) =
  Scenario
    { scenarioData
    | steps =
        messageSteps
          |> List.map (\f -> \specSubject ->
            f specSubject
              |> sendMessage
          )
          |> List.map (\step -> { run = step, condition = formatCondition condition })
          |> List.append scenarioData.steps
    }


it : String -> Expectation model msg -> Scenario model msg -> Scenario model msg
it description expectation (Scenario scenarioData) =
  Scenario
    { scenarioData
    | requirements = scenarioData.requirements ++
      [ { description = formatObservationDescription description
        , expectation = expectation
        }
      ]
    }


expect : Observer a -> Actual model a -> Expectation model msg
expect observer actual =
  Expectation <| \description config subject ->
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


formatSpecDescription : String -> String
formatSpecDescription description =
  "Describing: " ++ description


formatScenarioDescription : String -> String
formatScenarioDescription description =
  "Scenario: " ++ description


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
  { scenarios: List (Scenario model msg)
  , state: State model msg
  , procedureModel: Procedure.Program.Model (Msg msg)
  }


type State model msg
  = Ready
  | Configure (Scenario model msg)
  | Exercise (Scenario model msg) (ExerciseModel model msg)
  | Observe (Scenario model msg) (ObserveModel model msg)
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
    Exercise (Scenario scenarioData) exerciseModel ->
      scenarioData.subject.view exerciseModel.model
        |> Html.map ProgramMsg
    Observe (Scenario scenarioData) observeModel ->
      scenarioData.subject.view observeModel.model
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
        Exercise scenarioData exerciseModel ->
          ( { model | state = Exercise scenarioData { exerciseModel | effects = message :: exerciseModel.effects } }
          , config.send Lifecycle.stepComplete
          )
        _ ->
          ( model, Cmd.none )
    SendMessage message ->
      ( model, config.send message )
    ProgramMsg programMsg ->
      case model.state of
        Exercise (Scenario scenarioData) exerciseModel ->
          scenarioData.subject.update config.outlet programMsg exerciseModel.model
            |> Tuple.mapFirst (\updated -> { model | state = Exercise (Scenario scenarioData) { exerciseModel | model = updated } })
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
          case model.scenarios of
            [] ->
              ( model, config.send Lifecycle.specComplete )
            (Scenario scenarioData) :: remaining ->
              ( { model | scenarios = remaining, state = Configure (Scenario scenarioData) }
              , Cmd.batch
                [ config.send Lifecycle.configureComplete
                , Cmd.batch <| List.map config.send scenarioData.subject.configureEnvironment
                ]
              )
        Configure scenarioData ->
          ( { model | state = toExercise scenarioData }
          , goToNext
          )
        Exercise scenarioData exerciseModel ->
          case exerciseModel.steps of
            [] ->
              ( { model | state = toObserve scenarioData exerciseModel }
              , goToNext
              )
            step :: remaining ->
              ( { model | state = Exercise scenarioData
                  { exerciseModel
                  | steps = remaining
                  , conditionsApplied = addIfAbsent step.condition exerciseModel.conditionsApplied
                  }
                }
              , subjectFrom scenarioData
                  |> currentSubject exerciseModel
                  |> step.run
              )
        Observe scenarioData observeModel ->
          case observeModel.requirements of
            [] ->
              ( { model | state = Ready }, goToNext )
            requirement :: remaining ->
              ( { model | state = Observe scenarioData { observeModel | requirements = remaining } }
              , let
                  (Expectation expectation) = requirement.expectation
                in
                  subjectFrom scenarioData
                    |> currentSubject observeModel
                    |> expectation requirement.description config
              )
        Abort ->
          ( model, config.send Lifecycle.specComplete )
    Lifecycle.Abort report ->
      case model.state of
        Exercise scenarioData exerciseModel ->
          ( { model | state = Abort }
          , Observer.Reject report
              |> Observer.observation exerciseModel.conditionsApplied "A spec step failed"
              |> config.send
          )
        _ ->
          ( model, Cmd.none )


toExercise : Scenario model msg -> State model msg
toExercise (Scenario scenarioData) =
  Exercise (Scenario scenarioData)
    { conditionsApplied = scenarioData.subject.conditions
    , model = scenarioData.subject.model
    , effects = scenarioData.subject.effects
    , steps = scenarioData.steps
    }


toObserve : Scenario model msg -> ExerciseModel model msg -> State model msg
toObserve (Scenario scenarioData) exerciseModel =
  Observe (Scenario scenarioData)
    { conditionsApplied = exerciseModel.conditionsApplied
    , model = exerciseModel.model
    , effects = exerciseModel.effects
    , requirements = scenarioData.requirements
    }


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
    Exercise (Scenario scenarioData) exerciseModel ->
      Sub.batch
      [ Sub.map ProgramMsg <| Subject.subscriptions scenarioData.subject
      , Procedure.Program.subscriptions model.procedureModel
      ]
    _ ->
      Procedure.Program.subscriptions model.procedureModel
  

init : Config msg -> List (Spec model msg) -> () -> ( Model model msg, Cmd (Msg msg) )
init config specs _ =
  ( { scenarios =
        List.map (\(Spec scenarios) -> scenarios) specs
          |> List.concat
    , state = Ready
    , procedureModel = Procedure.Program.init
    }
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

subjectFrom : Scenario model msg -> Subject model msg
subjectFrom (Scenario scenarioData) =
  scenarioData.subject


addIfAbsent : a -> List a -> List a
addIfAbsent val list =
  if List.member val list then
    list
  else
    list ++ [ val ]