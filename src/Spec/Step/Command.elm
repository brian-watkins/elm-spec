module Spec.Step.Command exposing
  ( Command(..)
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
