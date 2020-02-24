module Spec.Markup exposing
  ( MarkupObservation
  , HtmlElement
  , ViewportOffset
  , observeTitle
  , observeBrowserViewport
  , observeElement
  , observeElements
  , query
  , target
  , property
  , text
  , attribute
  , log
  )

{-| Target, observe and make claims about aspects of an HTML document.

# Target an HTML Element
@docs target

# Observe an HTML Document
@docs MarkupObservation, observeElements, observeElement, query, observeTitle

# Make Claims about an HTML Element
@docs HtmlElement, text, attribute, property

# Observe the Browser
@docs ViewportOffset, observeBrowserViewport

# Debug
@docs log

-}

import Spec.Observer as Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Claim as Claim exposing (Claim)
import Spec.Report as Report exposing (Report)
import Spec.Markup.Selector as Selector exposing (Selector, Element)
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Step.Context as Context
import Spec.Message as Message exposing (Message)
import Spec.Markup.Message as Message
import Json.Encode as Encode
import Json.Decode as Json
import Dict exposing (Dict)


{-| Observe the title of an HTML document.

Note: It only makes sense to observe the title if your program is constructed with
`Browser.document` or `Browser.application`.
-}
observeTitle : Observer model String
observeTitle =
  Observer.inquire Message.fetchWindow <| \message ->
    Message.decode documentTitleDecoder message
      |> Result.withDefault ""


documentTitleDecoder : Json.Decoder String
documentTitleDecoder =
  Json.at [ "document", "title" ] Json.string


{-| Represents the offset of a viewport.
-}
type alias ViewportOffset =
  { x: Float
  , y: Float
  }


{-| Observe the browser's viewport offset.

Use this function to observe that the viewport of the browser window
has been set to a certain position via `Browser.Dom.setViewport`.

Note: If you'd like to observe the viewport offset of an *element* set via `Browser.Dom.setViewportOf`,
use `observeElement` and `property` to make a claim about its `scrollLeft` and `scrollTop` properties.

-}
observeBrowserViewport : Observer model ViewportOffset
observeBrowserViewport =
  Observer.inquire Message.fetchWindow <| \message ->
    Message.decode viewportOffsetDecoder message
      |> Result.withDefault { x = -1, y = -1 }


viewportOffsetDecoder : Json.Decoder ViewportOffset
viewportOffsetDecoder =
  Json.map2 ViewportOffset
    (Json.field "pageXOffset" Json.float)
    (Json.field "pageYOffset" Json.float)


{-| Represents an observation of HTML.
-}
type MarkupObservation a =
  MarkupObservation
    { query: Query
    , inquiryHandler: Selector Element -> Message -> Result Report a
    }


type Query
  = Single
  | All


{-| Observe an HTML element that matches the selector provided to `Spec.Markup.query`.

    Spec.Markup.observeElement
      |> Spec.Markup.query << by [ attribute ("data-attr", "some-value") ]
      |> Spec.expect (
        Spec.Claim.isSomethingWhere <|
        Spec.Markup.text <|
        Spec.Claim.isEqual Debug.toString "something fun"
      )

Claim that an element is not present in the document like so:

    Spec.Markup.observeElement
      |> Spec.Markup.query << by [ id "not-present" ]
      |> Spec.expect Spec.Claim.isNothing

-}
observeElement : MarkupObservation (Maybe HtmlElement)
observeElement =
  MarkupObservation
    { query = Single
    , inquiryHandler = \selection message ->
        Message.decode maybeHtmlDecoder message
          |> Result.mapError (\err ->
            Report.fact "Unable to decode element JSON!" err
          )
    }


{-| Observe all HTML elements that match the selector provided to `Spec.Markup.query`.

    Spec.Markup.observeElements
      |> Spec.Markup.query << by [ attribute ("data-attr", "some-value") ]
      |> Spec.expect (Spec.Claim.isListWithLength 3)

If no elements match the query, then the subject of the claim will be an empty list.
-}
observeElements : MarkupObservation (List HtmlElement)
observeElements =
  MarkupObservation
    { query = All
    , inquiryHandler = \selection message ->
        Message.decode (Json.list htmlDecoder) message
          |> Result.mapError (\err ->
            Report.fact "Unable to decode element JSON!" err
          )
    }


{-| Search for HTML elements.

Use this function in conjunction with `observe`, `observeElement`, or `observeElements` to
observe the HTML document.
-}
query : (Selector Element, MarkupObservation a) -> Observer model a
query (selection, MarkupObservation observation) =
  let
    message =
      queryMessage observation.query selection
  in
    Observer.inquire message (observation.inquiryHandler selection)
      |> Observer.observeResult
      |> Observer.mapRejection (\report ->
        Report.batch
        [ Report.fact "Claim rejected for selector" <| Selector.toString selection
        , report
        ]
      )


{-| A step that identifies an element to which later steps will be applied.

    Spec.when "the button is clicked twice"
      [ Spec.Markup.target << by [ tag "button" ]
      , Spec.Markup.Event.click
      , Spec.Markup.Event.click
      ]

-}
target : (Selector a, Step.Context model) -> Step.Command msg
target (selection, context) =
  Message.for "_html" "target"
    |> Message.withBody (Encode.string <| Selector.toString selection)
    |> Command.sendMessage


queryMessage : Query -> Selector Element -> Message
queryMessage queryType selection =
  Message.for "_html" (queryName queryType)
    |> Message.withBody (
      Encode.object
        [ ( "selector", Encode.string <| Selector.toString selection )
        ]
    )


queryName : Query -> String
queryName queryType =
  case queryType of
    Single ->
      "query"
    All ->
      "queryAll"


{-| Represents an HTML element.
-}
type HtmlElement =
  HtmlElement Json.Value


maybeHtmlDecoder : Json.Decoder (Maybe HtmlElement)
maybeHtmlDecoder =
  Json.oneOf
    [ Json.null Nothing
    , Json.map Just <| htmlDecoder
    ]


htmlDecoder : Json.Decoder HtmlElement
htmlDecoder =
  Json.map HtmlElement <| Json.value


{-| Claim that the HTML element's text satisfies the given claim.

    Spec.Markup.observeElement
      |> Spec.Markup.query << by [ tag "div" ]
      |> Spec.expect (
        Spec.Claim.isSomethingWhere <|
        Spec.Markup.text <|
        Spec.Claim.isStringContaining 1 "red"
      )

Note that an observed HTML element's text includes the text belonging to
all its descendants.
-}
text : Claim String -> Claim HtmlElement
text claim =
  \(HtmlElement element) ->
    case Json.decodeValue (Json.field "textContent" Json.string) element of
      Ok actualText ->
        claim actualText
          |> Claim.mapRejection (\report -> Report.batch
            [ Report.note "Claim rejected for element text"
            , report
            ]
          )
      Err err ->
        Claim.Reject <| Report.fact "Unable to decode JSON for text" <| Json.errorToString err


{-| Claim that the specified attribute value satisfies the given claim.

    Spec.Markup.observeElement
      |> Spec.Markup.query << by [ tag "div" ]
      |> Spec.expect (
        Spec.Claim.isSomethingWhere <|
        Spec.Markup.attribute "class" <|
        Spec.Claim.isSomethingWhere <|
        Spec.Claim.isStringContaining 1 "red"
      )

If you receive an error that the attribute you're interested in is not found, try `Spec.Markup.property`
instead. Elm-spec is examining the actual DOM element, and it's not always clear whether Elm uses
the attribute or the associated property to configure the element.

On the difference between attributes and properties,
see [this](https://github.com/elm-lang/html/blob/master/properties-vs-attributes.md).

-}
attribute : String -> Claim (Maybe String) -> Claim HtmlElement
attribute name claim =
  \(HtmlElement element) ->
    case Json.decodeValue attributesDecoder element of
      Ok attributes ->
        Dict.get name attributes
          |> claim
          |> Claim.mapRejection (\report -> Report.batch
              [ Report.fact "Claim rejected for attribute" name
              , report
              ]
          )
      Err err ->
        Claim.Reject <| Report.fact "Unable to decode JSON for attributes" <| Json.errorToString err


attributesDecoder : Json.Decoder (Dict String String)
attributesDecoder =
  Json.map Dict.fromList <|
    Json.field "attributes" <|
    Json.map (List.map Tuple.second) <|
    Json.keyValuePairs <|
    Json.map2 Tuple.pair
      (Json.field "name" Json.string)
      (Json.field "value" Json.string)


{-| Apply the given decoder to the HTML element and make a claim about the resulting value.

Use this function to observe a property of an HTML element. For example, you could observe whether
a button is disabled like so:

    Spec.Markup.observeElement
      |> Spec.Markup.query << by [ tag "button" ]
      |> Spec.expect (
        Spec.Claim.isSomethingWhere <|
        Spec.Markup.property
          (Json.Decode.field "disabled" Json.Decode.bool)
          Spec.Claim.isTrue
      )

Some common properties one might make claims about and the type of the corresponding value:

- `style`  (an object)
- `hidden` (a boolean value)
- `disabled` (a boolean value)
- `scrollLeft`, `scrollTop` (the element's viewport offset, float values)
- `checked` (a boolean value)
- `value` (a string)

On the difference between attributes and properties,
see [this](https://github.com/elm-lang/html/blob/master/properties-vs-attributes.md).

-}
property : Json.Decoder a -> Claim a -> Claim HtmlElement
property decoder claim =
  \(HtmlElement element) ->
    case Json.decodeValue decoder element of
      Ok propertyValue ->
        claim propertyValue
      Err err ->
        Claim.Reject <| Report.fact "Unable to decode JSON for property" <| Json.errorToString err


{-| A step that logs to the console the selected HTML element and its descendants.

    Spec.when "the button is clicked twice"
      [ Spec.Markup.target << by [ tag "button" ]
      , Spec.Markup.Event.click
      , Spec.Markup.log << by [ id "click-counter" ]
      , Spec.Markup.Event.click
      ]

If an element is currently targeted, logging a different element does not change
the targeted element.

You might use this to help debug a rejected observation.

-}
log : (Selector Element, Step.Context model) -> Step.Command msg
log (selector, context) =
  fetchElementMessage selector
    |> Command.sendRequest (andThenLogElement selector)


andThenLogElement : Selector Element -> Message -> Step.Command msg
andThenLogElement selector message =
  Message.decode maybeHtmlDecoder message
    |> Result.withDefault Nothing
    |> Maybe.map (elementToReport selector)
    |> Maybe.withDefault (
      Report.fact "No element found for selector" (Selector.toString selector)
    )
    |> Command.log


elementToReport : Selector Element -> HtmlElement -> Report
elementToReport selector (HtmlElement element) =
  case Json.decodeValue (Json.field "outerHTML" Json.string) element of
    Ok html ->
      Report.fact ("HTML for element: " ++ Selector.toString selector) html
    Err err ->
      Json.errorToString err
        |> Report.fact ("Unable to decode outerHTML for element: " ++ Selector.toString selector)


fetchElementMessage : Selector Element -> Message
fetchElementMessage selector =
  Message.for "_html" (queryName Single)
    |> Message.withBody (
      Encode.object
        [ ( "selector", Encode.string <| Selector.toString selector )
        ]
    )
