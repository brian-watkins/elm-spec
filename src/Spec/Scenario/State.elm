module Spec.Scenario.State exposing
  ( Msg(..)
  , Command(..)
  )

import Spec.Message exposing (Message)
import Spec.Observation.Report exposing (Report)


type Msg msg
  = ReceivedMessage Message
  | ProgramMsg msg
  | Continue
  | Abort Report


type Command msg
  = Do (Cmd msg)
  | Send Message
  | SendMany (List Message)
  | Transition