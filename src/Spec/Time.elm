module Spec.Time exposing
  ( withTime
  , tick
  , nextAnimationFrame
  )

import Spec.Subject as Subject exposing (SubjectGenerator)
import Spec.Step as Step
import Spec.Markup.Message as Message
import Json.Encode as Encode


withTime : Int -> SubjectGenerator model msg -> SubjectGenerator model msg
withTime posix =
  { home = "_time"
  , name = "set-time"
  , body = Encode.int posix
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
