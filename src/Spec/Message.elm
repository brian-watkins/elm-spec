module Spec.Message exposing
  ( Message
  , decode
  , belongsTo
  , is
  )

import Json.Encode exposing (Value)
import Json.Decode as Json

type alias Message =
  { home: String
  , name: String
  , body: Value
  }


belongsTo : String -> Message -> Bool
belongsTo home message =
  message.home == home


is : String -> String -> Message -> Bool
is home name message =
  message.home == home && message.name == name


decode : Json.Decoder a -> Message -> Maybe a
decode decoder message =
  Json.decodeValue decoder message.body
    |> Result.toMaybe