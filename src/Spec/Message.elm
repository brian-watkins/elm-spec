module Spec.Message exposing
  ( Message
  , decode
  , belongsTo
  , is
  , decoder
  , encode
  )

import Json.Encode as Encode exposing (Value)
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
decode messageDecoder message =
  Json.decodeValue messageDecoder message.body
    |> Result.toMaybe


decoder : Json.Decoder Message
decoder =
  Json.map3 Message
    ( Json.field "home" Json.string )
    ( Json.field "name" Json.string )
    ( Json.field "body" Json.value )


encode : Message -> Encode.Value
encode message =
  Encode.object
  [ ( "home", Encode.string message.home )
  , ( "name", Encode.string message.name )
  , ( "body", message.body )
  ]
