module Spec.Step exposing
  ( Step
  , Context
  , Command
  , sendCommand
  , sendMessage
  , build
  , run
  , condition
  )

import Spec.Message exposing (Message)
import Spec.Subject as Subject exposing (Subject)
import Spec.Step.Command as Command


type Step model msg =
  Step
    { run: Context model -> Command msg
    , condition: String
    }


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


build : String -> (Context model -> Command msg) -> Step model msg
build description stepper =
  Step
    { run = stepper
    , condition = description
    }


run : Step model msg -> Context model -> Command msg
run (Step step) =
  step.run


condition : Step model msg -> String
condition (Step step) =
  step.condition