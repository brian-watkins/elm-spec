module Spec.Markup.Event exposing
  ( click
  , doubleClick
  , mouseDown
  , mouseUp
  , mouseMoveIn
  , mouseMoveOut
  , input
  , selectOption
  , resizeWindow
  , hideWindow
  , showWindow
  , focus
  , blur
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


focus : Step.Context model -> Step.Command msg
focus =
  basicEventMessage "focus"


blur : Step.Context model -> Step.Command msg
blur =
  basicEventMessage "blur"


mouseMoveIn : Step.Context model -> Step.Command msg
mouseMoveIn =
  basicEventMessage "mouseMoveIn"


mouseMoveOut : Step.Context model -> Step.Command msg
mouseMoveOut =
  basicEventMessage "mouseMoveOut"


basicEventMessage : String -> Step.Context model -> Step.Command msg
basicEventMessage name context =
  Message.for "_html" name
    |> Message.withBody (
      Encode.object
        [ ( "selector", Encode.string <| targetSelector context )
        ]
    )
    |> Step.sendMessage


input : String -> Step.Context model -> Step.Command msg
input text context =
  Message.for "_html" "input"
    |> Message.withBody (
      Encode.object
        [ ( "selector", Encode.string <| targetSelector context )
        , ( "text", Encode.string text )
        ]
    )
    |> Step.sendMessage


selectOption : String -> Step.Context model -> Step.Command msg
selectOption text context =
  Message.for "_html" "select"
    |> Message.withBody (
      Encode.object
        [ ( "selector", Encode.string <| targetSelector context )
        , ( "text", Encode.string text )
        ]
    )
    |> Step.sendMessage


resizeWindow : (Int, Int) -> Step.Context model -> Step.Command msg
resizeWindow (width, height) _ =
  Message.for "_html" "resize"
    |> Message.withBody (
      Encode.object
        [ ( "width", Encode.int width )
        , ( "height", Encode.int height )
        ]
    )
    |> Step.sendMessage


hideWindow : Step.Context model -> Step.Command msg
hideWindow =
  setWindowVisible False


showWindow : Step.Context model -> Step.Command msg
showWindow =
  setWindowVisible True


setWindowVisible : Bool -> Step.Context model -> Step.Command msg
setWindowVisible isVisible _ =
  Message.for "_html" "visibilityChange"
    |> Message.withBody (
      Encode.object
        [ ( "isVisible", Encode.bool isVisible )
        ]
    )
    |> Step.sendMessage


trigger : String -> Encode.Value -> Step.Context model -> Step.Command msg
trigger name json context =
  Message.for "_html" "customEvent"
    |> Message.withBody (
      Encode.object
        [ ( "selector", Encode.string <| targetSelector context )
        , ( "name", Encode.string name )
        , ( "event", json )
        ]
    )
    |> Step.sendMessage


targetSelector : Step.Context model -> String
targetSelector context =
  context.effects
    |> List.filter (Message.is "_html" "target")
    |> List.head
    |> Maybe.andThen (Message.decode Json.string)
    |> Maybe.withDefault ""
