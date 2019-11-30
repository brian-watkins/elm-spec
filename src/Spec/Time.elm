module Spec.Time exposing
  ( withTime
  , withTimezoneOffset
  , tick
  , nextAnimationFrame
  )

import Spec.Subject as Subject exposing (SubjectProvider)
import Spec.Step as Step
import Spec.Markup.Message as Message
import Json.Encode as Encode


withTime : Int -> SubjectProvider model msg -> SubjectProvider model msg
withTime posix =
  { home = "_time"
  , name = "set-time"
  , body = Encode.int posix
  }
  |> Subject.configure


withTimezoneOffset : Int -> SubjectProvider model msg -> SubjectProvider model msg
withTimezoneOffset zoneOffset =
  { home = "_time"
  , name = "set-timezone"
  , body = Encode.int zoneOffset
  }
  |> Subject.configure


tick : Int -> Step.Context model -> Step.Command msg
tick duration _ =
  Step.sendMessage
    { home = "_time"
    , name = "tick"
    , body = Encode.int duration
    }


nextAnimationFrame : Step.Context model -> Step.Command msg
nextAnimationFrame _ =
  Step.sendMessage
    Message.runToNextAnimationFrame
