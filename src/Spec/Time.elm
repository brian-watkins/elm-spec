module Spec.Time exposing
  ( withTime
  , withTimezoneOffset
  , tick
  , nextAnimationFrame
  )

import Spec.Setup as Setup exposing (Setup)
import Spec.Setup.Internal as Setup
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Message as Message
import Spec.Markup.Message as Message
import Json.Encode as Encode


withTime : Int -> Setup model msg -> Setup model msg
withTime posix =
  Message.for "_time" "set-time"
    |> Message.withBody (Encode.int posix)
    |> Setup.configure


withTimezoneOffset : Int -> Setup model msg -> Setup model msg
withTimezoneOffset zoneOffset =
  Message.for "_time" "set-timezone"
    |> Message.withBody (Encode.int zoneOffset)
    |> Setup.configure


tick : Int -> Step.Context model -> Step.Command msg
tick duration _ =
  Message.for "_time" "tick"
    |> Message.withBody (Encode.int duration)
    |> Command.sendMessage


nextAnimationFrame : Step.Context model -> Step.Command msg
nextAnimationFrame _ =
  Command.sendMessage
    Message.runToNextAnimationFrame
