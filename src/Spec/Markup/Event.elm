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

{-| Use these steps to trigger events during a scenario.

To trigger an event, you'll want to first use `Spec.Markup.target` to target a
particular element (or the document as a whole) to which subsequent events should apply.

For example,

    Spec.describe "a form"
    [ Spec.scenario "completing the form" (
        Spec.given (
          testSubject
        )
        |> when "the form is revealed"
          [ Spec.Markup.target << by [ id "show-form" ]
          , Spec.Markup.Event.click
          ]
        |> when "the name is entered"
          [ Spec.Markup.target << by [ id "first-name-field" ]
          , Spec.Markup.Event.input "Brian"
          , Spec.Markup.target << by [ id "last-name-field" ]
          , Spec.Markup.Event.input "Watkins"
          ]
        |> when "the form is submitted"
          [ Spec.Markup.target << by [ id "submit" ]
          , Spec.Markup.Event.click
          ]
        |> it "does something cool" (
          ...
        )
      )
    ]

# Mouse Events
@docs click, doubleClick, mouseDown, mouseUp, mouseMoveIn, mouseMoveOut

# Form Events
@docs input, selectOption

# Window Events
@docs resizeWindow, hideWindow, showWindow

# Focus Events
@docs focus, blur

# Custom Events
@docs trigger

-}

import Spec.Step as Step
import Spec.Message as Message
import Json.Encode as Encode
import Json.Decode as Json


{-| A step that simulates a click event on the targeted item, either the
document as a whole (using the `Spec.Markup.Selector.document` selector or
some particular HTML element).

This will trigger `mousedown`, `mouseup`, and `click` DOM events on the targeted item.

In several cases, you can use `click` to trigger other kinds of events. Use `click` to
simulate checking or unchecking a checkbox. Use `click` to select a radio button. Use
`click` to submit a form by clicking the associated button.
-}
click : Step.Context model -> Step.Command msg
click =
  basicEventMessage "click"


{-| A step that simulates a double click on the targeted HTML element.

This will trigger two sets of `mouseup`, `mousedown`, and `click` DOM events and then a `dblclick` DOM event.
-}
doubleClick : Step.Context model -> Step.Command msg
doubleClick =
  basicEventMessage "doubleClick"


{-| A step that simulates pressing the mouse button on the targeted item, either the
document as a whole (using the `Spec.Markup.Selector.document` selector or
some particular HTML element).

This will trigger a `mouseDown` DOM event on the targeted item.
-}
mouseDown : Step.Context model -> Step.Command msg
mouseDown =
  trigger "mousedown" <| Encode.object []


{-| A step that simulates releasing the mouse button on the targeted item, either the
document as a whole (using the `Spec.Markup.Selector.document` selector or
some particular HTML element).

This will trigger a `mouseup` DOM event on the targeted item.
-}
mouseUp : Step.Context model -> Step.Command msg
mouseUp =
  trigger "mouseup" <| Encode.object []


{-| A step that simulates the targeted HTML element receiving focus.

This will trigger a `focus` DOM event on the targeted element.
-}
focus : Step.Context model -> Step.Command msg
focus =
  basicEventMessage "focus"


{-| A step that simulates the targeted HTML element losing focus.

This will trigger a `blur` DOM event on the targeted element.
-}
blur : Step.Context model -> Step.Command msg
blur =
  basicEventMessage "blur"


{-| A step that simulates the mouse moving into the targeted HTML element.

This will trigger `mouseover` and `mouseenter` DOM events on the targeted element.
-}
mouseMoveIn : Step.Context model -> Step.Command msg
mouseMoveIn =
  basicEventMessage "mouseMoveIn"


{-| A step that simulates the mouse moving out of the targeted HTML element.

This will trigger `mouseout` and `mouseleave` DOM events on the targeted element.
-}
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


{-| A step that simulates text input to the targeted HTML element.

This will set the `value` attribute of the targeted element to the given string
and trigger an `input` DOM event on that element.

To trigger input events on a radio button just target the button and simulate a click on it.

To trigger input events on a select, use `selectOption`.
-}
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


{-| A step that simulates selecting an option from the menu generated by a `<select>` element.

This will select the option whose text or label matches the given string, and then trigger `change` and
`input` DOM events on the targeted HTML `<select>` element.
-}
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


{-| A step that simulates resizing the browser window to the given (width, height).

This will trigger a `resize` DOM event on the window object.
-}
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


{-| A step that simulates hiding the window from view.

This will trigger a `visibilitychange` DOM event on the document object.
-}
hideWindow : Step.Context model -> Step.Command msg
hideWindow =
  setWindowVisible False


{-| A step that simulates the window returning into view.

This will trigger a `visibilitychange` DOM event on the document object.
-}
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


{-| A step that triggers a custom DOM event on the targeted item.

Provide the name of the DOM event and a JSON value that specifes any properties to add to the event object.

For example, to simulate releasing the `A` key:

    Spec.when "The A key is released"
      [ Spec.Markup.target << by [ id "my-field" ]
      , Json.Encode.object [ ( "keyCode", Encode.int 65 ) ]
          |> Spec.Markup.event.trigger "keyup"
      ]

You may trigger a custom DOM event on the document (by selecting it with `Spec.Markup.Selector.document`)
or some particular HTML element.

-}
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
