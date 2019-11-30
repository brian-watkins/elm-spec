module Spec.Time exposing
  ( withTime
  , withTimezoneOffset
  , tick
  , nextAnimationFrame
  )

import Spec.Subject as Subject exposing (SubjectProvider)
import Spec.Step as Step
import Spec.Message as Message
import Spec.Markup.Message as Message
import Json.Encode as Encode


withTime : Int -> SubjectProvider model msg -> SubjectProvider model msg
withTime posix =
  Message.for "_time" "set-time"
    |> Message.withBody (Encode.int posix)
    |> Subject.configure


withTimezoneOffset : Int -> SubjectProvider model msg -> SubjectProvider model msg
withTimezoneOffset zoneOffset =
  Message.for "_time" "set-timezone"
    |> Message.withBody (Encode.int zoneOffset)
    |> Subject.configure


tick : Int -> Step.Context model -> Step.Command msg
tick duration _ =
  Message.for "_time" "tick"
    |> Message.withBody (Encode.int duration)
    |> Step.sendMessage


nextAnimationFrame : Step.Context model -> Step.Command msg
nextAnimationFrame _ =
  Step.sendMessage
    Message.runToNextAnimationFrame
