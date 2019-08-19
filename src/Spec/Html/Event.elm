module Spec.Html.Event exposing
  ( click
  , input
  )

import Spec.Subject exposing (Subject)
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


click : Subject model msg -> Message
click subject =
  { home = "_html"
  , name = "click"
  , body = Encode.object
    [ ( "selector", Encode.string <| targetSelector subject )
    ]
  }


input : String -> Subject model msg -> Message
input text subject =
  { home = "_html"
  , name = "input"
  , body = Encode.object
    [ ( "selector", Encode.string <| targetSelector subject )
    , ( "text", Encode.string text )
    ]
  }


targetSelector : Subject model msg -> String
targetSelector subject =
  subject.effects
    |> List.filter (Message.is "_html" "target")
    |> List.head
    |> Maybe.andThen (Message.decode Json.string)
    |> Maybe.withDefault ""
