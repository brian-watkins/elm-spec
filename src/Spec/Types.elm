module Spec.Types exposing
  ( Msg(..)
  )

import Spec.Message exposing (Message)
import Observer exposing (Verdict)


type Msg msg
  = ProgramMsg msg
  | ReceivedMessage Message
  | SendMessage Message
  | NextStep
  | ObserveSubject
