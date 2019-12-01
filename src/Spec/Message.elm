module Spec.Message exposing
  ( Message
  , for
  , withBody
  , decode
  , belongsTo
  , is
  )

import Json.Encode as Encode exposing (Value)
import Json.Decode as Json


type alias Message =
  { home: String
  , name: String
  , body: Value
  }


for : String -> String -> Message
for home name =
  { home = home
  , name = name
  , body = Encode.null
  }


withBody : Value -> Message -> Message
withBody value message =
  { message | body = value }


belongsTo : String -> Message -> Bool
belongsTo home message =
  message.home == home


is : String -> String -> Message -> Bool
is home name message =
  message.home == home && message.name == name


decode : Json.Decoder a -> Message -> Maybe a
decode messageDecoder message =
  Json.decodeValue messageDecoder message.body
    |> Result.toMaybe
