module Spec.Markup.Navigation exposing
  ( selectLocation
  )

import Spec.Observation as Observation exposing (Selection)
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


selectLocation : Selection model String
selectLocation =
  Observation.inquire selectLocationMessage
    |> Observation.mapSelection (Message.decode Json.string)
    |> Observation.mapSelection (Maybe.withDefault "FAILED")


selectLocationMessage : Message
selectLocationMessage =
  { home = "_html"
  , name = "navigation"
  , body = Encode.string "select-location"
  }