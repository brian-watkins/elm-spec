module Spec exposing
  ( Spec, Scenario
  , describe, scenario
  , when, it
  , Model, Msg, Config
  , update, view, init, subscriptions
  , program, browserProgram
  )

import Spec.Observer as Observer
import Spec.Observation.Message as Message
import Spec.Message as Message exposing (Message)
import Spec.Lifecycle as Lifecycle
import Spec.Subject as Subject exposing (Subject)
import Spec.Step as Step exposing (Step)
import Spec.Step.Command as StepCommand
import Spec.Observation as Observation exposing (Observation)
import Spec.Observation.Internal as Observation_
import Task
import Html exposing (Html)
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
    , observations: List ({ description: String, observation: Observation model })
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
        [ Step.build (formatScenarioDescription description) <|
            \_ ->
              Step.sendCommand specSubject.initialCommand
        ]
    , observations = []
    }


when : String -> List (Step.Context model -> Step.Command msg) -> Scenario model msg -> Scenario model msg
when condition messageSteps (Scenario scenarioData) =
  Scenario
    { scenarioData
    | steps =
        messageSteps
          |> List.map (Step.build <| formatCondition condition)
          |> List.append scenarioData.steps
    }


it : String -> Observation model -> Scenario model msg -> Scenario model msg
it description observation (Scenario scenarioData) =
  Scenario
    { scenarioData
    | observations = List.append scenarioData.observations
        [ { description = formatObservationDescription description
          , observation = observation 
          }
        ]
    }


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
  | Observe (Scenario model msg) (ObserveModel model)
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


type alias ObserveModel model =
  StateModel model
    { observations: (List ({ description: String, observation: Observation model }))
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
                  , conditionsApplied =
                      Step.condition step
                        |> addIfUnique exerciseModel.conditionsApplied
                  }
                }
              , { model = exerciseModel.model, effects = exerciseModel.effects }
                  |> Step.run step 
                  |> StepCommand.map ProgramMsg
                  |> StepCommand.withDefault goToNext
                  |> StepCommand.toCmdOr sendMessage
              )
        Observe scenarioData observeModel ->
          case observeModel.observations of
            [] ->
              ( { model | state = Ready }, goToNext )
            observation :: remaining ->
              ( { model | state = Observe scenarioData { observeModel | observations = remaining } }
              , Observation_.toProcedure config (toObservationContext observeModel) observation.observation
                  |> Procedure.map (Message.observation observeModel.conditionsApplied observation.description)
                  |> Procedure.run ProcedureMsg SendMessage
              )
        Abort ->
          ( model, config.send Lifecycle.specComplete )
    Lifecycle.Abort report ->
      case model.state of
        Exercise scenarioData exerciseModel ->
          ( { model | state = Abort }
          , Observer.Reject report
              |> Message.observation exerciseModel.conditionsApplied "A spec step failed"
              |> config.send
          )
        _ ->
          ( model, Cmd.none )


toObservationContext : ObserveModel model -> Observation_.Context model
toObservationContext observeModel =
  { model = observeModel.model
  , effects = observeModel.effects
  }


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
    , observations = scenarioData.observations
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


addIfUnique : List a -> a -> List a
addIfUnique list val =
  if List.member val list then
    list
  else
    list ++ [ val ]