module Spec.Time exposing
  ( fake
  , tick
  )

import Spec.Subject as Subject exposing (Subject)
import Spec.Message exposing (Message)
import Json.Encode as Encode

fake : Subject model msg -> Subject model msg
fake =
  { home = "_time"
  , name = "setup"
  , body = Encode.null
  }
  |> Subject.configure


tick : Int -> Subject model msg -> Message
tick duration _ =
  { home = "_time"
  , name = "tick"
  , body = Encode.int duration
  }