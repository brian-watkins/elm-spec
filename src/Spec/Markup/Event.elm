module Spec.Markup.Event exposing
  ( click
  , doubleClick
  , mouseDown
  , mouseUp
  , mouseMoveIn
  , mouseMoveOut
  , input
  , resizeWindow
  , trigger
  )

import Spec.Step as Step
import Spec.Message as Message
import Json.Encode as Encode
import Json.Decode as Json


click : Step.Context model -> Step.Command msg
click =
  basicEventMessage "click"


doubleClick : Step.Context model -> Step.Command msg
doubleClick =
  basicEventMessage "doubleClick"


mouseDown : Step.Context model -> Step.Command msg
mouseDown =
  trigger "mousedown" <| Encode.object []


mouseUp : Step.Context model -> Step.Command msg
mouseUp =
  trigger "mouseup" <| Encode.object []


mouseMoveIn : Step.Context model -> Step.Command msg
mouseMoveIn =
  basicEventMessage "mouseMoveIn"


mouseMoveOut : Step.Context model -> Step.Command msg
mouseMoveOut =
  basicEventMessage "mouseMoveOut"


basicEventMessage : String -> Step.Context model -> Step.Command msg
basicEventMessage name context =
  Step.sendMessage
    { home = "_html"
    , name = name
    , body = Encode.object
      [ ( "selector", Encode.string <| targetSelector context )
      ]
    }


input : String -> Step.Context model -> Step.Command msg
input text context =
  Step.sendMessage
    { home = "_html"
    , name = "input"
    , body = Encode.object
      [ ( "selector", Encode.string <| targetSelector context )
      , ( "text", Encode.string text )
      ]
    }


resizeWindow : (Int, Int) -> Step.Context model -> Step.Command msg
resizeWindow (width, height) context =
  Step.sendMessage
    { home = "_html"
    , name = "resize"
    , body = Encode.object
      [ ( "width", Encode.int width )
      , ( "height", Encode.int height )
      ]
    }


trigger : String -> Encode.Value -> Step.Context model -> Step.Command msg
trigger name json context =
  Step.sendMessage
    { home = "_html"
    , name = "customEvent"
    , body = Encode.object
      [ ( "selector", Encode.string <| targetSelector context )
      , ( "name", Encode.string name )
      , ( "event", json )
      ]
    }


targetSelector : Step.Context model -> String
targetSelector context =
  context.effects
    |> List.filter (Message.is "_html" "target")
    |> List.head
    |> Maybe.andThen (Message.decode Json.string)
    |> Maybe.withDefault ""
