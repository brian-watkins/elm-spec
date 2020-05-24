module Spec.Markup.Event exposing
  ( click
  , doubleClick
  , mouseDown
  , mouseUp
  , mouseMoveIn
  , mouseMoveOut
  , input
  , selectOption
  , focus
  , blur
  , ViewportOffset
  , setViewportOffset
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

# Focus Events
@docs focus, blur

# Control the Viewport
@docs ViewportOffset, setViewportOffset

# Custom Events
@docs trigger

-}

import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Step.Context as Context
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


{-| A step that simulates a click event on the targeted item, either the
document as a whole (using the `Spec.Markup.Selector.document` selector or
some particular HTML element).

This will trigger `mousedown`, `mouseup`, and `click` DOM events on the targeted item.

In several cases, you can use `click` to trigger other kinds of events. Use `click` to
simulate checking or unchecking a checkbox. Use `click` to select a radio button. Use
`click` to submit a form by clicking the associated button.

You can also use `click` on an anchor tag, but here the behavior is a
little more complicated.

First of all, any click event handlers associated with the anchor tag will
be triggered as expected.

If the anchor tag has an `href` attribute, then
elm-spec can *usually* intercept the navigation, which allows you to use `Spec.Navigation.observeLocation`
to make a claim about the location to which you've navigated. Elm-spec will simulate going to another
page by replacing the program's view with a page that states the program has navigated
outside the Elm context.

If the anchor tag has an `href` attribute *and* a `target` attribute or a `download` attribute
then elm-spec will *not* intercept the navigation. This means that the navigation will
proceed as if the program were actually running, and this will usually cause your
specs to get into a bad state. So, rather than clicking such a link during a scenario, you
should instead just observe that it has the `href` attribute you expect.

-}
-- click : Step.Step model msg
click : Step.Step model msg
click =
  basicEventMessage "click"


{-| A step that simulates a double click on the targeted HTML element.

This will trigger two sets of `mouseup`, `mousedown`, and `click` DOM events and then a `dblclick` DOM event.
-}
doubleClick : Step.Step model msg
doubleClick =
  basicEventMessage "doubleClick"


{-| A step that simulates pressing the mouse button on the targeted item, either the
document as a whole (using the `Spec.Markup.Selector.document` selector or
some particular HTML element).

This will trigger a `mouseDown` DOM event on the targeted item.
-}
mouseDown : Step.Step model msg
mouseDown =
  trigger "mousedown" <| Encode.object []


{-| A step that simulates releasing the mouse button on the targeted item, either the
document as a whole (using the `Spec.Markup.Selector.document` selector or
some particular HTML element).

This will trigger a `mouseup` DOM event on the targeted item.
-}
mouseUp : Step.Step model msg
mouseUp =
  trigger "mouseup" <| Encode.object []


{-| A step that simulates the targeted HTML element receiving focus.

This will trigger a `focus` DOM event on the targeted element.
-}
focus : Step.Step model msg
focus =
  basicEventMessage "focus"


{-| A step that simulates the targeted HTML element losing focus.

This will trigger a `blur` DOM event on the targeted element.
-}
blur : Step.Step model msg
blur =
  basicEventMessage "blur"


{-| A step that simulates the mouse moving into the targeted HTML element.

This will trigger `mouseover` and `mouseenter` DOM events on the targeted element.
-}
mouseMoveIn : Step.Step model msg
mouseMoveIn =
  basicEventMessage "mouseMoveIn"


{-| A step that simulates the mouse moving out of the targeted HTML element.

This will trigger `mouseout` and `mouseleave` DOM events on the targeted element.
-}
mouseMoveOut : Step.Step model msg
mouseMoveOut =
  basicEventMessage "mouseMoveOut"


basicEventMessage : String -> Step.Step model msg
basicEventMessage name context =
  Message.for "_html" name
    |> Message.withBody (
      Encode.object
        [ ( "selector", Encode.string <| targetSelector context )
        ]
    )
    |> Command.sendMessage


{-| A step that simulates text input to the targeted HTML element.

This will set the `value` attribute of the targeted element to the given string
and trigger an `input` DOM event on that element.

To trigger input events on a radio button just target the button and simulate a click on it.

To trigger input events on a select, use `selectOption`.
-}
input : String -> Step.Step model msg
input text =
  \context ->
    Message.for "_html" "input"
      |> Message.withBody (
        Encode.object
          [ ( "selector", Encode.string <| targetSelector context )
          , ( "text", Encode.string text )
          ]
      )
      |> Command.sendMessage


{-| A step that simulates selecting an option from the menu generated by a `<select>` element.

This will select the option whose text or label matches the given string, and then trigger `change` and
`input` DOM events on the targeted HTML `<select>` element.
-}
selectOption : String -> Step.Step model msg
selectOption text =
  \context ->
    Message.for "_html" "select"
      |> Message.withBody (
        Encode.object
          [ ( "selector", Encode.string <| targetSelector context )
          , ( "text", Encode.string text )
          ]
      )
      |> Command.sendMessage


{-| Represents the offset of a viewport.
-}
type alias ViewportOffset =
  { x: Float
  , y: Float
  }


{-| A step that changes the offset of the targeted element's viewport.

Use this step to simulate a user scrolling the content within an element.

Note that elm-spec does not fake the element viewport offset. So, if you are running
specs in a real browser (via Karma), then the element must be scrollable for this step
to do anything (i.e., it probably needs a fixed height or width, and it's `overflow`
CSS property must be set appropriately).

-}
setViewportOffset : ViewportOffset -> Step.Step model msg
setViewportOffset offset =
  \context ->
    Message.for "_html" "set-element-viewport"
      |> Message.withBody (
        Encode.object
          [ ( "selector", Encode.string <| targetSelector context )
          , ( "viewport", encodeViewportOffset offset )
          ]
      )
      |> Command.sendMessage


encodeViewportOffset : ViewportOffset -> Encode.Value
encodeViewportOffset offset =
  Encode.object
  [ ("x", Encode.float offset.x)
  , ("y", Encode.float offset.y)
  ]


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
trigger : String -> Encode.Value -> Step.Step model msg
trigger name json =
  \context ->
    Message.for "_html" "customEvent"
      |> Message.withBody (
        Encode.object
          [ ( "selector", Encode.string <| targetSelector context )
          , ( "name", Encode.string name )
          , ( "event", json )
          ]
      )
      |> Command.sendMessage


targetSelector : Step.Context model -> String
targetSelector context =
  Context.effects context
    |> List.filter (Message.is "_html" "target")
    |> List.head
    |> Maybe.andThen (Result.toMaybe << Message.decode Json.string)
    |> Maybe.withDefault ""
