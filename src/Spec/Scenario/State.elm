module Spec.Scenario.State exposing
  ( Msg(..)
  , Model(..)
  , StateProgram
  , Actions
  , updateWith
  , abortWith
  , send
  , sendMany
  , continue
  )

import Spec.Message exposing (Message)
import Spec.Scenario.Message as Message
import Spec.Observer.Message as Message
import Spec.Claim as Claim
import Spec.Report as Report exposing (Report)
import Browser exposing (UrlRequest, Document)
import Url exposing (Url)
import Task


type Msg msg
  = ReceivedMessage Message
  | ProgramMsg msg
  | Continue
  | Abort Report
  | OnUrlRequest UrlRequest
  | OnUrlChange Url


type Model msg programMsg
  = Running (StateProgram msg programMsg)
  | Waiting


type alias StateProgram msg programMsg =
  { update: Actions msg programMsg -> Msg programMsg -> ( Model msg programMsg, Cmd msg )
  , view: Maybe (Document programMsg)
  , subscriptions: Maybe (Sub programMsg)
  }


type alias Actions msg programMsg =
  { complete: Cmd msg
  , send: Message -> Cmd msg
  , sendToSelf: Msg programMsg -> msg
  , outlet: Message -> Cmd programMsg
  , stop: Cmd msg
  }


updateWith : Actions msg programMsg -> (Msg programMsg) -> Cmd msg
updateWith actions msg =
  Task.succeed never
    |> Task.perform (always msg)
    |> Cmd.map actions.sendToSelf


abortWith : Actions msg programMsg -> List String -> String -> Report -> Cmd msg
abortWith actions conditions description report =
  [ Claim.Reject report
      |> Message.observation conditions description
  , Message.abortScenario
  ]
    |> List.map actions.send
    |> Cmd.batch


send : Actions msg programMsg -> Message -> Cmd msg
send actions message =
  actions.send message


sendMany : Actions msg programMsg -> List Message -> Cmd msg
sendMany actions messages =
  Cmd.batch <| List.map actions.send messages


continue : Actions msg programMsg -> Cmd msg
continue actions =
  Task.succeed never
    |> Task.perform (always Continue)
    |> Cmd.map actions.sendToSelf
