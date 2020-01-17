module Spec.Scenario.Program exposing
  ( Config, Model, init, update, view, subscriptions
  , start
  , receivedMessage
  , finishScenario
  )

import Spec.Scenario.Internal as Internal exposing (Scenario)
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.Message as Message
import Spec.Scenario.State exposing (Msg(..), Command(..))
import Spec.Message as Message exposing (Message)
import Spec.Observer.Message as Message
import Spec.Markup.Message as Message
import Spec.Observer.Expectation as Expectation
import Spec.Report as Report exposing (Report)
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


type alias Model model msg =
  State model msg


type State model msg
  = Ready
  | Start (Scenario model msg) (Subject model msg)
  | Configure (Configure.Model model msg)
  | Exercise (Exercise.Model model msg)
  | Observe (Observe.Model model msg)
  | Finished (Finished.Model model msg)


type alias Config msg programMsg =
  { complete: Cmd msg
  , send: Message -> Cmd msg
  , sendToSelf: Msg programMsg -> msg
  , outlet: Message -> Cmd programMsg
  , stop: Cmd msg
  }


start : Config msg programMsg -> Maybe Key -> Scenario model programMsg -> ( Model model programMsg, Cmd msg )
start config maybeKey scenario =
  case Internal.initializeSubject scenario.setup maybeKey of
    Ok subject ->
      ( Start scenario subject
      , config.send Message.startScenario
      )
    Err error ->
      ( Ready
      , Report.note error
          |> abortWith [] "Scenario Failed" 
          |> List.map config.send
          |> Cmd.batch
      )


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


view : Model model programMsg -> Document (Msg programMsg)
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


update : Config msg programMsg -> Msg programMsg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
update config msg state =
  case msg of
    ReceivedMessage message ->
      if Message.isScenarioMessage message then
        update config (toMsg message) state
      else
        case state of
          Exercise model ->
            exerciseUpdate config msg model
          Observe model ->
            observeUpdate config msg model
          Finished model ->
            finishedUpdate config msg model
          _ ->
            badState config state
        
    ProgramMsg programMsg ->
      case state of
        Exercise model ->
          exerciseUpdate config msg model
        Finished model ->
          finishedUpdate config msg model
        _ ->
          badState config state

    Continue ->
      case state of
        Start scenario subject ->
          case Configure.init scenario subject of
            ( updated, Send message ) ->
              ( Configure updated, config.send message )
            ( updated, SendMany messages ) ->
              ( Configure updated, Cmd.batch <| List.map config.send messages )
            ( updated, _ ) ->
              badState config state
        Configure model ->
          update config Continue <| Exercise <| Exercise.init model.scenario model.subject
        Exercise model ->
          exerciseUpdate config msg model
        Observe model ->
          observeUpdate config msg model
        Finished model ->
          ( state, config.complete )
        Ready ->
          ( Ready, config.complete )

    Abort report ->
      case state of
        Exercise model ->
          ( Finished <| Finished.init model.subject model.programModel
          , abortWith model.conditionsApplied "A spec step failed" report
              |> List.map config.send
              |> Cmd.batch
          )
        Configure model ->
          ( Ready
          , abortWith [ model.scenario.specification, model.scenario.description ] "Unable to configure scenario" report
              |> List.map config.send
              |> Cmd.batch
          )
        Observe model ->
          ( Finished <| Finished.init model.subject model.programModel
          , abortWith (model.conditionsApplied ++ [ model.currentDescription ]) "Unable to complete observation" report
              |> List.map config.send
              |> Cmd.batch
          )
        _ ->
          ( Ready
          , abortWith [] "Scenario Failed" report
              |> List.map config.send
              |> Cmd.batch
          )

    OnUrlChange _ ->
      case state of
        Exercise model ->
          exerciseUpdate config msg model
        Finished model ->
          finishedUpdate config msg model
        _ ->
          badState config state

    OnUrlRequest _ ->
      case state of
        Exercise model ->
          exerciseUpdate config msg model
        Finished model ->
          finishedUpdate config msg model
        _ ->
          badState config state


abortWith : List String -> String -> Report -> List Message
abortWith conditions description report =
  [ Claim.Reject report
      |> Message.observation conditions description
  , Message.abortScenario
  ]


exerciseUpdate : Config msg programMsg -> Msg programMsg -> Exercise.Model model programMsg -> ( Model model programMsg, Cmd msg )
exerciseUpdate config msg model =
  case Exercise.update config.outlet msg model of
    ( updated, Do cmd ) ->
      ( Exercise updated, Cmd.map config.sendToSelf cmd )
    ( updated, DoAndRender cmd ) ->
      ( Exercise updated
      , Cmd.batch
        [ Cmd.map config.sendToSelf cmd
        , config.send <| Message.stepMessage <| Message.runToNextAnimationFrame
        ]
      )
    ( updated, Send message ) ->
      ( Exercise updated, config.send <| Message.stepMessage <| message )
    ( updated, SendMany messages ) ->
      ( Exercise updated, Cmd.batch <| List.map config.send messages )
    ( updated, Transition ) ->
      ( Observe <| Observe.init updated, config.send Message.startObservation )


observeUpdate : Config msg programMsg -> Msg programMsg -> Observe.Model model programMsg -> ( Model model programMsg, Cmd msg )
observeUpdate config msg model =
  case Observe.update msg model of
    ( updated, Send message ) ->
      ( Observe updated, config.send message )
    ( updated, Transition ) ->
      ( Finished <| Finished.init model.subject model.programModel
      , config.complete
      )
    ( updated, _ ) ->
      badState config <| Observe updated


finishedUpdate : Config msg programMsg -> Msg programMsg -> Finished.Model model programMsg -> ( Model model programMsg, Cmd msg )
finishedUpdate config msg model =
  case Finished.update config.outlet msg model of
    ( updated, Do cmd ) ->
      ( Finished updated, Cmd.map config.sendToSelf cmd )
    ( updated, DoAndRender cmd ) ->
      ( Finished updated
      , Cmd.batch
        [ Cmd.map config.sendToSelf cmd
        , config.send Message.runToNextAnimationFrame
        ]
      )
    ( updated, Send message ) ->
      ( Finished updated, config.send message )
    ( updated, _ ) ->
      badState config <| Finished updated


finishScenario : Model model programMsg -> Model model programMsg
finishScenario state =
  case state of
    Observe model ->
      Finished <| Finished.init model.subject model.programModel
    _ ->
      state


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
