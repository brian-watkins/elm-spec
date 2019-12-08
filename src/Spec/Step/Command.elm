module Spec.Step.Command exposing
  ( Command(..)
  , map
  , withDefault
  , toCmdOr
  , sendCommand
  , sendMessage
  )

import Spec.Message exposing (Message)


type Command msg
  = SendMessage Message
  | SendCommand (Cmd msg)
  | DoNothing


sendCommand : Cmd msg -> Command msg
sendCommand cmd =
  if cmd == Cmd.none then
    DoNothing
  else
    SendCommand cmd


sendMessage : Message -> Command msg
sendMessage =
  SendMessage


map : (msg -> a) -> Command msg -> Command a
map mapper stepCommand =
  case stepCommand of
    SendMessage message ->
      SendMessage message
    SendCommand command ->
      SendCommand <| Cmd.map mapper command
    DoNothing ->
      DoNothing


withDefault : Cmd msg -> Command msg -> Command msg
withDefault default stepCommand =
  case stepCommand of
    SendMessage message ->
      SendMessage message
    SendCommand command ->
      SendCommand command
    DoNothing ->
      SendCommand default


toCmdOr : (Message -> Cmd msg) -> Command msg -> Cmd msg
toCmdOr sender stepCommand =
  case stepCommand of
    SendMessage message ->
      sender message
    SendCommand command ->
      command
    DoNothing ->
      Cmd.none

