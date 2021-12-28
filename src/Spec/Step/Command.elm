module Spec.Step.Command exposing
  ( Command(..)
  , sendToProgram
  , sendMessage
  , sendRequest
  , recordCondition
  , nothing
  , log
  , halt
  , batch
  , recordEffect
  , programCommand
  )

import Spec.Message as Message exposing (Message)
import Spec.Step.Message as Message
import Spec.Report as Report exposing (Report)


type Command msg
  = SendMessage Message
  | SendRequest Message (Message -> Command msg)
  | SendCommand (Cmd msg)
  | RecordCondition String
  | Halt Report
  | Batch (List (Command msg))
  | RecordEffect Message


sendToProgram : Cmd msg -> Command msg
sendToProgram cmd =
  SendCommand cmd


sendMessage : Message -> Command msg
sendMessage =
  SendMessage


halt : Report -> Command msg
halt =
  Halt


batch : List (Command msg) -> Command msg
batch =
  Batch


recordEffect : Message -> Command msg
recordEffect =
  RecordEffect


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