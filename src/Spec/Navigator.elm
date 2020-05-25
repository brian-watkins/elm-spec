module Spec.Navigator exposing
  ( Navigator
  , ViewportOffset
  , observe
  , title
  , viewportOffset
  , location
  , expectReload
  , resize
  , hide
  , show
  , setViewportOffset
  )

{-| Observe and make claims about how the Browser presents an HTML document: its title, its location,
the viewport parameters, window visibility, and so on.

# Observe Navigator Properties
@docs Navigator, observe, title, ViewportOffset, viewportOffset, location, expectReload

# Navigator Events
@docs resize, setViewportOffset, hide, show

-}

import Spec exposing (Expectation)
import Spec.Observer as Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Message as Message exposing (Message)
import Spec.Claim as Claim exposing (Claim)
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Report as Report
import Json.Decode as Json
import Json.Encode as Encode


{-| Represents the Browser's presentation of an HTML document.
-}
type Navigator
  = Navigator Window


type alias Window =
  { title: String
  , viewportOffset: { x: Float, y: Float }
  , location: String
  }


{-| Represents the offset of a viewport.
-}
type alias ViewportOffset =
  { x: Float
  , y: Float
  }


{-| Observe how a Browser presents an HTML document.
-}
observe : Observer model Navigator
observe =
  Observer.observeResult <|
    Observer.inquire fetchWindow (\message ->
      Message.decode navigatorDecoder message
        |> Result.mapError (Report.fact "Unable to decode window JSON!")
    )


{-| Claim that the title of the HTML document satisfies the given claim.

    Spec.it "has the correct title" (
      Spec.Navigator.observe
        |> Spec.expect (
          Spec.Navigator.title <|
            Spec.Claim.isEqual Debug.toString
              "My Cool App"
        )
    )

Note: It only makes sense to make a claim about the title if your program is
constructed with `Browser.document` or `Browser.application`.
-}
title : Claim String -> Claim Navigator
title claim =
  \(Navigator window) ->
    claim window.title


{-| Claim that the location of the document satisfies the given claim.

    Spec.it "has the correct location" (
      Spec.Navigator.observe
        |> Spec.expect (
          Spec.Navigator.location <|
            Spec.Claim.isEqual Debug.toString
              "http://fake-server.com/something-fun"
        )
    )

This is useful to observe that `Browswer.Navigation.load`,
`Browser.Navigation.pushUrl`, or `Browser.Navigation.replaceUrl` was
executed with the value you expect.

Note that you can use [Spec.Setup.withLocation](Spec.Setup#withLocation) to set the base location
of the document at the start of the scenario.

-}
location : Claim String -> Claim Navigator
location claim =
  \(Navigator window) ->
    claim window.location


{-| Claim that the browser's viewport offset satisfies the given claim.

Use this function to claim that the viewport of the browser window
has been set to a certain position via `Browser.Dom.setViewport`.

    Spec.it "has the correct scroll position" (
      Spec.Navigator.observe
        |> Spec.expect (
          Spec.Navigator.viewportOffset <|
            Spec.Claim.specifyThat .y <|
            Spec.Claim.isEqual Debug.toString 27
        )
    )

Note: If you'd like to make a claim about the viewport offset of an *element* set via
`Browser.Dom.setViewportOf`, use [Spec.Markup.observeElement](Spec.Markup#observeElement)
and [Spec.Markup.property](Spec.Markup#property) to make a claim about its
`scrollLeft` and `scrollTop` properties.

-}
viewportOffset : Claim ViewportOffset -> Claim Navigator
viewportOffset claim =
  \(Navigator window) ->
    claim window.viewportOffset


{-| Expect that a `Browser.Navigation.reload` or `Browser.Navigation.reloadAndSkipCache`
command was executed.
-}
expectReload : Expectation model
expectReload =
  Observer.observeEffects (List.filter (Message.is "_navigation" "reload"))
    |> Spec.expect (\messages ->
      if List.length messages > 0 then
        Claim.Accept
      else
        Claim.Reject <| Report.note "Expected Browser.Navigation.reload or Browser.Navigation.reloadAndSkipCache but neither command was executed"
    )


{-| A step that simulates resizing the browser window to the given (width, height).

This will trigger a `resize` DOM event on the window object.

By default, elm-spec sets the browser window size to 1280 x 800.

Note that elm-spec fakes the browser window size. So if you are viewing elm-spec
specs in a real browser, then you won't actually see the window size
change, but the Elm program will think it has.

-}
resize : (Int, Int) -> Step.Step model msg
resize (width, height) =
  \_ ->
    Message.for "_html" "resize"
      |> Message.withBody (
        Encode.object
          [ ( "width", Encode.int width )
          , ( "height", Encode.int height )
          ]
      )
      |> Command.sendMessage


{-| A step that simulates hiding the window from view.

This will trigger a `visibilitychange` DOM event on the document object.

Note that elm-spec fakes the browser window visibility. So if you are viewing elm-spec
specs in a real browser, then you won't actually see the window visibility change,
but the Elm program will think it has.

-}
hide : Step.Step model msg
hide =
  setWindowVisible False


{-| A step that simulates the window returning into view.

This will trigger a `visibilitychange` DOM event on the document object.

Note that elm-spec fakes the browser window visibility. So if you are viewing elm-spec
specs in a real browser, then you won't actually see the window visibility change,
but the Elm program will think it has.

-}
show : Step.Step model msg
show =
  setWindowVisible True


setWindowVisible : Bool -> Step.Step model msg
setWindowVisible isVisible _ =
  Message.for "_html" "visibilityChange"
    |> Message.withBody (
      Encode.object
        [ ( "isVisible", Encode.bool isVisible )
        ]
    )
    |> Command.sendMessage


{-| A step that changes the offset of the browser viewport.

Use this step to simulate a user scrolling the web page.

By default, elm-spec sets the browser viewport offset to `{ x = 0, y = 0 }`.

Note that elm-spec fakes the browser viewport offset. So if you are viewing elm-spec
specs in a real browser, then you won't actually see the viewport offset
change, but the Elm program will think it has.

-}
setViewportOffset : ViewportOffset -> Step.Step model msg
setViewportOffset offset =
  \_ ->
    Message.for "_html" "set-browser-viewport"
      |> Message.withBody (encodeViewportOffset offset)
      |> Command.sendMessage


encodeViewportOffset : ViewportOffset -> Encode.Value
encodeViewportOffset offset =
  Encode.object
  [ ("x", Encode.float offset.x)
  , ("y", Encode.float offset.y)
  ]


navigatorDecoder : Json.Decoder Navigator
navigatorDecoder =
  Json.map Navigator windowDecoder


windowDecoder : Json.Decoder Window
windowDecoder =
  Json.map3 Window
    (Json.at [ "document", "title" ] Json.string)
    (viewportOffsetDecoder)
    (Json.at [ "location", "href" ] Json.string)


viewportOffsetDecoder : Json.Decoder ViewportOffset
viewportOffsetDecoder =
  Json.map2 ViewportOffset
    (Json.field "pageXOffset" Json.float)
    (Json.field "pageYOffset" Json.float)


fetchWindow : Message
fetchWindow =
  Message.for "_html" "query-window"