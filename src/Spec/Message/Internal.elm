module Spec.Message.Internal exposing
  ( encode
  , decoder
  )

import Spec.Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


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
