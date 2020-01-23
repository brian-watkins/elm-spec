module Spec.Scenario.State exposing
  ( Msg(..)
  , Command(..)
  , Actions
  , updateWith
  , abortWith
  , abortMessages
  , send
  , sendMany
  , continue
  )

import Spec.Message exposing (Message)
import Spec.Scenario.Message as Message
import Spec.Observer.Message as Message
import Spec.Claim as Claim
import Spec.Report as Report exposing (Report)
import Browser exposing (UrlRequest)
import Url exposing (Url)
import Task


type Msg msg
  = ReceivedMessage Message
  | ProgramMsg msg
  | Continue
  | Abort Report
  | OnUrlRequest UrlRequest
  | OnUrlChange Url


type alias Actions msg programMsg =
  { complete: Cmd msg
  , send: Message -> Cmd msg
  , sendToSelf: Msg programMsg -> msg
  , outlet: Message -> Cmd programMsg
  , stop: Cmd msg
  }


type Command msg
  = Do (Cmd msg)
  | Halt (Cmd msg)
  | Transition (Cmd msg)


updateWith : Actions msg programMsg -> (Msg programMsg) -> Command msg
updateWith actions msg =
  Task.succeed never
    |> Task.perform (always msg)
    |> Cmd.map actions.sendToSelf
    |> Do


abortWith : Actions msg programMsg -> List String -> String -> Report -> Command msg
abortWith actions conditions description report =
  abortMessages conditions description report
    |> List.map actions.send
    |> Cmd.batch
    |> Halt


abortMessages : List String -> String -> Report -> List Message
abortMessages conditions description report =
  [ Claim.Reject report
      |> Message.observation conditions description
  , Message.abortScenario
  ]


send : Actions msg programMsg -> Message -> Command msg
send actions message =
  Do <| actions.send message


sendMany : Actions msg programMsg -> List Message -> Command msg
sendMany actions messages =
  Do <| Cmd.batch <| List.map actions.send messages


continue : Actions msg programMsg -> Cmd msg
continue actions =
  Task.succeed never
    |> Task.perform (always Continue)
    |> Cmd.map actions.sendToSelf
