module Spec.Step.Command exposing
  ( Command(..)
  , sendToProgram
  , sendMessage
  , sendRequest
  , recordCondition
  , nothing
  , log
  , programCommand
  )

import Spec.Message exposing (Message)
import Spec.Report as Report exposing (Report)
import Spec.Message as Message


type Command msg
  = SendMessage Message
  | SendRequest Message (Message -> Command msg)
  | SendCommand (Cmd msg)
  | RecordCondition String


sendToProgram : Cmd msg -> Command msg
sendToProgram cmd =
  SendCommand cmd


sendMessage : Message -> Command msg
sendMessage =
  SendMessage


recordCondition : String -> Command msg
recordCondition =
  RecordCondition


sendRequest : (Message -> Command msg) -> Message -> Command msg
sendRequest responseHandler message =
  SendRequest message responseHandler


log : Report -> Command msg
log report =
  Message.for "_step" "log"
    |> Message.withBody (Report.encode report)
    |> sendMessage


programCommand : Message
programCommand =
  Message.for "_step" "program-command"


nothing : Command msg
nothing =
  SendCommand Cmd.none