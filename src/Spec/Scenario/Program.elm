module Spec.Scenario.Program exposing
  ( Config, Model, init, update, view, subscriptions
  , with
  , start
  , receivedMessage
  )

import Spec.Scenario exposing (Scenario)
import Spec.Scenario.Message as Message
import Spec.Scenario.State exposing (Msg(..), Command(..))
import Spec.Message as Message exposing (Message)
import Spec.Observation.Message as Message
import Spec.Observation.Expectation as Expectation
import Spec.Observation.Report as Report exposing (Report)
import Spec.Scenario.State.Exercise as Exercise
import Spec.Scenario.State.Configure as Configure
import Spec.Scenario.State.Observe as Observe
import Spec.Observer as Observer
import Html exposing (Html)
import Json.Decode as Json
import Task


type alias Model model msg =
  State model msg


type State model msg
  = Start (Scenario model msg)
  | Configure (Configure.Model model msg)
  | Exercise (Exercise.Model model msg)
  | Observe (Observe.Model model msg)
  | Ready


type alias Config msg programMsg =
  { complete: Cmd msg
  , send: Message -> Cmd msg
  , sendToSelf: Msg programMsg -> msg
  , outlet: Message -> Cmd programMsg
  , stop: Cmd msg
  }


with : Scenario model msg -> Model model msg
with scenario =
  Start scenario


start : Cmd (Msg msg)
start =
  Task.succeed never
    |> Task.perform (always Continue)


continue : Config msg programMsg -> Cmd msg
continue config =
  Task.succeed never
    |> Task.perform (always Continue)
    |> Cmd.map config.sendToSelf


init : Model model msg
init =
  Ready


receivedMessage : Message -> Msg msg
receivedMessage =
  ReceivedMessage


subscriptions : Model model programMsg -> Sub (Msg programMsg)
subscriptions state =
  case state of
    Exercise model ->
      Exercise.subscriptions model
        |> Sub.map ProgramMsg
    _ ->
      Sub.none


view : Model model programMsg -> Html (Msg programMsg)
view state =
  case state of
    Exercise model ->
      Exercise.view model
        |> Html.map ProgramMsg
    Observe model ->
      Observe.view model
        |> Html.map ProgramMsg
    _ ->
      Html.text ""


update : Config msg programMsg -> Msg programMsg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
update config msg state =
  case msg of
    ReceivedMessage message ->
      if Message.isScenarioMessage message then
        update config (toMsg message) state
      else
        case state of
          Exercise model ->
            case Exercise.update config.outlet msg model of
              ( updated, Send nextMessage ) ->
                ( Exercise updated, config.send nextMessage )
              ( updated, _ ) ->
                badState config state
          Observe model ->
            case Observe.update msg model of
              ( updated, Send nextMessage ) ->
                ( Observe updated, config.send nextMessage )
              ( updated, _ ) ->
                badState config state
          _ ->
            badState config state
        
    ProgramMsg programMsg ->
      case state of
        Exercise model ->
          case Exercise.update config.outlet msg model of
            ( updated, Do cmd ) ->
              ( Exercise updated, Cmd.map config.sendToSelf cmd )
            ( updated, Send message ) ->
              ( Exercise updated, config.send message )
            ( updated, _ ) ->
              badState config state
        _ ->
          badState config state

    Continue ->
      case state of
        Ready ->
          ( Ready, Cmd.none )
        Start scenario ->
          case Configure.init scenario of
            ( updated, SendMany messages ) ->
              ( Configure updated, Cmd.batch <| List.map config.send messages )
            ( updated, _ ) ->
              badState config state
        Configure model ->
          update config Continue <| toExercise model.scenario
        Exercise model ->
          case Exercise.update config.outlet msg model of
            ( updated, Do cmd ) ->
              ( Exercise updated, Cmd.map config.sendToSelf cmd )
            ( updated, Send message ) ->
              ( Exercise updated, config.send message )
            ( updated, Transition ) ->
              update config Continue <| toObserve updated
            ( updated, _ ) ->
              badState config state
        Observe model ->
          case Observe.update msg model of
            ( updated, Send message ) ->
              ( Observe updated, config.send message )
            ( updated, Transition ) ->
              ( Ready, config.complete )
            ( updated, _ ) ->
              badState config state

    Abort report ->
      case state of
        Exercise model ->
          case Exercise.update config.outlet msg model of
            ( updated, Send message ) ->
              ( Ready, Cmd.batch [ config.stop, config.send message ])
            ( updated, _ ) ->
              badState config state
        _ ->
          ( Ready
          , Cmd.batch 
            [ config.stop
            , Observer.Reject report
                |> Message.observation [] "Scenario Failed"
                |> config.send 
            ]
          )


badState : Config msg programMsg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
badState config model =
  update config (Abort <| Report.note "Unknown scenario state!") model


toMsg : Message -> Msg msg
toMsg message =
  case message.name of
    "state" ->
      Message.decode Json.string message
        |> Maybe.map toStateMsg
        |> Maybe.withDefault (Abort <| Report.note "Unable to parse scenario state event!")
    "abort" ->
      Message.decode Report.decoder message
        |> Maybe.withDefault (Report.note "Unable to parse abort scenario event!")
        |> Abort
    unknown ->
      Abort <| Report.fact "Unknown scenario event" unknown


toStateMsg : String -> Msg msg
toStateMsg specState =
  case specState of
    "CONTINUE" ->
      Continue
    unknown ->
      Abort <| Report.fact "Unknown scenario state" unknown


toExercise : Scenario model msg -> State model msg
toExercise scenarioData =
  Exercise
    { scenario = scenarioData
    , conditionsApplied = scenarioData.subject.conditions
    , programModel = scenarioData.subject.model
    , effects = scenarioData.subject.effects
    , steps = scenarioData.steps
    }


toObserve : Exercise.Model model msg -> State model msg
toObserve exerciseModel =
  Observe
    { scenario = exerciseModel.scenario
    , conditionsApplied = exerciseModel.conditionsApplied
    , programModel = exerciseModel.programModel
    , effects = exerciseModel.effects
    , observations = exerciseModel.scenario.observations
    , expectationModel = Expectation.init
    , currentDescription = ""
    }
