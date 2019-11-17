module Spec.Time exposing
  ( fake
  , tick
  , nextAnimationFrame
  )

import Spec.Subject as Subject exposing (SubjectGenerator)
import Spec.Step as Step
import Spec.Markup.Message as Message
import Json.Encode as Encode


fake : SubjectGenerator model msg -> SubjectGenerator model msg
fake =
  { home = "_time"
  , name = "setup"
  , body = Encode.null
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
