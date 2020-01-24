module Spec.Scenario.Program exposing
  ( State, init, update, view, subscriptions
  , start
  , receivedMessage
  , finishScenario
  )

import Spec.Scenario.Internal as Internal exposing (Scenario)
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.Message as Message
import Spec.Scenario.State as State exposing (Msg(..), Command(..), Actions)
import Spec.Message as Message exposing (Message)
import Spec.Observer.Message as Message
import Spec.Markup.Message as Message
import Spec.Report as Report exposing (Report)
import Spec.Scenario.State.Start as Start
import Spec.Scenario.State.Exercise as Exercise
import Spec.Scenario.State.Configure as Configure
import Spec.Scenario.State.Observe as Observe
import Spec.Scenario.State.Finished as Finished
import Spec.Claim as Claim
import Spec.Helpers exposing (mapDocument)
import Html exposing (Html)
import Json.Decode as Json
import Task
import Browser exposing (Document)
import Browser.Navigation exposing (Key)


type State model msg
  = Ready
  | Start (Start.Model model msg)
  | Configure (Configure.Model model msg)
  | Exercise (Exercise.Model model msg)
  | Observe (Observe.Model model msg)
  | Finished (Finished.Model model msg)


start : Actions msg programMsg -> Maybe Key -> Scenario model programMsg -> ( State model programMsg, Cmd msg )
start actions maybeKey scenario =
  case Internal.initializeSubject scenario.setup maybeKey of
    Ok subject ->
      ( Start <| Start.init scenario subject
      , actions.send Message.startScenario
      )
    Err error ->
      ( Ready
      , Report.note error
          |> State.abortMessages [] "Scenario Failed"
          |> List.map actions.send
          |> Cmd.batch
      )


init : State model msg
init =
  Ready


receivedMessage : Message -> Msg msg
receivedMessage =
  ReceivedMessage


subscriptions : State model programMsg -> Sub (Msg programMsg)
subscriptions state =
  case state of
    Exercise model ->
      Exercise.subscriptions model
        |> Sub.map ProgramMsg
    _ ->
      Sub.none


view : State model programMsg -> Document (Msg programMsg)
view state =
  case state of
    Exercise model ->
      Exercise.view model
        |> mapDocument ProgramMsg
    Observe model ->
      Observe.view model
        |> mapDocument ProgramMsg
    Finished model ->
      Finished.view model
        |> mapDocument ProgramMsg
    _ ->
      { title = "", body = [ Html.text "" ] }


update : Actions msg programMsg -> Msg programMsg -> State model programMsg -> ( State model programMsg, Cmd msg )
update actions msg state =
  case msg of
    ReceivedMessage message ->
      if Message.isScenarioMessage message then
        update actions (toMsg message) state
      else
        updateState actions msg state
    _ ->
      updateState actions msg state


updateState : Actions msg programMsg -> Msg programMsg -> State model programMsg -> ( State model programMsg, Cmd msg )
updateState actions msg state =
  case state of
    Ready ->
      ( Ready, actions.complete )

    Start model ->
      case Start.update actions msg model of
        ( updated, Transition cmd ) ->
          ( Configure <| Configure.init updated.scenario updated.subject, cmd )
        _ ->
          badState actions state

    Configure model ->
      case Configure.update actions msg model of
        ( updated, Transition cmd ) ->
          ( Exercise <| Exercise.init updated.scenario updated.subject, cmd )
        ( updated, Halt cmd ) ->
          ( Finished <| Finished.init updated.subject updated.subject.model, cmd )
        ( updated, Do cmd ) ->
          ( Configure updated, cmd )

    Exercise model ->
      case Exercise.update actions msg model of
        ( updated, Do cmd ) ->
          ( Exercise updated, cmd )
        ( updated, Transition cmd ) ->
          ( Observe <| Observe.init updated, cmd )
        ( updated, Halt cmd ) ->
          ( Finished <| Finished.init model.subject model.programModel, cmd )

    Observe model ->
      case Observe.update actions msg model of
        ( updated, Do cmd ) ->
          ( Observe updated, cmd )
        ( updated, Transition cmd ) ->
          ( Finished <| Finished.init updated.subject updated.programModel, cmd )
        ( updated, Halt cmd ) ->
          ( Finished <| Finished.init updated.subject updated.programModel, cmd )
    
    Finished model ->
      case Finished.update actions msg model of
        ( updated, Do cmd ) ->
          ( Finished updated, cmd )
        _ ->
          badState actions state


finishScenario : State model programMsg -> State model programMsg
finishScenario state =
  case state of
    Observe model ->
      Finished <| Finished.init model.subject model.programModel
    _ ->
      state


badState : Actions msg programMsg -> State model programMsg -> ( State model programMsg, Cmd msg )
badState actions model =
  ( Ready
  , Report.note "Unknown scenario state!"
      |> State.abortMessages [] "Scenario Failed"
      |> List.map actions.send
      |> Cmd.batch
  )


toMsg : Message -> Msg msg
toMsg message =
  case message.name of
    "state" ->
      Message.decode Json.string message
        |> Result.map toStateMsg
        |> Result.withDefault (Abort <| Report.note "Unable to parse scenario state event!")
    "abort" ->
      Message.decode Report.decoder message
        |> Result.withDefault (Report.note "Unable to parse abort scenario event!")
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
