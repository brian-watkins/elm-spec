module Spec.Scenario.Program exposing
  ( init, update, view, subscriptions
  , run
  , skip
  , receivedMessage
  , halt
  )

import Spec.Scenario.Internal exposing (Scenario)
import Spec.Setup.Internal as Internal
import Spec.Scenario.Message as Message
import Spec.Scenario.State as State exposing (Msg(..), Actions, StateProgram)
import Spec.Message as Message exposing (Message)
import Spec.Report as Report
import Spec.Scenario.State.Start as Start
import Spec.Scenario.State.Error as Error
import Spec.Scenario.State.Observe as Observe
import Spec.Helpers exposing (mapDocument)
import Html
import Json.Decode as Json
import Browser exposing (Document)
import Browser.Navigation exposing (Key)


run : Actions msg programMsg -> Maybe Key -> Scenario model programMsg -> ( State.Model msg programMsg, Cmd msg )
run actions maybeKey scenario =
  case Internal.initializeSubject scenario.setup maybeKey of
    Ok subject ->
      Start.init actions scenario subject
    Err error ->
      Report.note error
        |> Error.init actions [] "Scenario Failed"


skip : Actions msg programMsg -> Scenario model programMsg -> ( State.Model msg programMsg, Cmd msg )
skip =
  Observe.initForSkip


init : State.Model msg programMsg
init =
  State.Waiting


receivedMessage : Message -> Msg msg
receivedMessage =
  ReceivedMessage


halt : Msg msg
halt =
  Abort <| Report.note ""


subscriptions : State.Model msg programMsg -> Sub (Msg programMsg)
subscriptions state =
  case state of
    State.Waiting ->
      Sub.none
    State.Running model ->
      case model.subscriptions of
        Just subs ->
          Sub.map ProgramMsg subs
        Nothing ->
          Sub.none


view : State.Model msg programMsg -> Document (Msg programMsg)
view state =
  case state of
    State.Waiting ->
      { title = ""
      , body = [ Html.text "" ]
      }
    State.Running model ->
      case model.view of
        Just document ->
          mapDocument ProgramMsg document
        Nothing ->
          { title = ""
          , body = [ Html.text "" ]
          }


update : Actions msg programMsg -> Msg programMsg -> State.Model msg programMsg -> ( State.Model msg programMsg, Cmd msg )
update actions msg model =
  case model of
    State.Waiting ->
      ( model, Cmd.none )
    State.Running stateProgram ->
      case msg of
        ReceivedMessage message ->
          if Message.isScenarioMessage message then
            update actions (toMsg message) model
          else
            updateState actions msg stateProgram
        _ ->
          updateState actions msg stateProgram


updateState : Actions msg programMsg -> Msg programMsg -> StateProgram msg programMsg -> ( State.Model msg programMsg, Cmd msg )
updateState actions msg stateProgram =
  stateProgram.update actions msg


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
