module Spec.Step exposing
  ( Context
  , Command
  , sendCommand
  , sendMessage
  )

import Spec.Message exposing (Message)
import Spec.Step.Command as Command


type alias Context model =
  { model: model
  , effects: List Message
  }


type alias Command msg =
  Command.Command msg


sendCommand : Cmd msg -> Command msg
sendCommand cmd =
  if cmd == Cmd.none then
    Command.DoNothing
  else
    Command.SendCommand cmd


sendMessage : Message -> Command msg
sendMessage =
  Command.SendMessage
