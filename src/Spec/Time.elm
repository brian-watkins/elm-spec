module Spec.Time exposing
  ( fake
  , tick
  )

import Spec.Subject as Subject exposing (Subject)
import Spec.Step as Step
import Json.Encode as Encode

fake : Subject model msg -> Subject model msg
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