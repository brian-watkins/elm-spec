module Spec.Markup exposing
  ( MarkupObservation
  , HtmlElement
  , observeTitle
  , observe
  , observeElement
  , observeElements
  , query
  , target
  , hasText
  , hasAttribute
  )

{-| Target, observe and make claims about aspects of an HTML document.

# Target an HTML Element
@docs target

# Observe an HTML Document
@docs MarkupObservation, observeElements, observeElement, observe, query, observeTitle

# Make Claims about an HTML Element
@docs HtmlElement, hasText, hasAttribute

-}

import Spec.Observer as Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Claim as Claim exposing (Claim)
import Spec.Report as Report exposing (Report)
import Spec.Markup.Selector as Selector exposing (Selector, Element)
import Spec.Step as Step
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json
import Dict exposing (Dict)


{-| Observe the title of an HTML document.

Note: It only makes sense to observe the title if your program is constructed with
`Browser.document` or `Browser.application`.
-}
observeTitle : Observer model String
observeTitle =
  Observer.inquire selectTitleMessage <| \message ->
    Message.decode Json.string message
      |> Maybe.withDefault "FAILED"


selectTitleMessage : Message
selectTitleMessage =
  Message.for "_html" "application"
    |> Message.withBody (Encode.string "select-title")


{-| Represents an observation of HTML.
-}
type MarkupObservation a =
  MarkupObservation
    (Selector Element -> Message, Selector Element -> Message -> Result Report a)


{-| Observe an HTML element that may not be present in the document.

Use this observer if you want to make a claim about the presence or absence of an HTML element.

    Spec.Markup.observe
      |> Spec.Markup.query << by [ id "some-element" ]
      |> Spec.expect Spec.Claim.isNothing

-}
observe : MarkupObservation (Maybe HtmlElement)
observe =
  MarkupObservation
    ( queryHtml
    , \selection message ->
        Ok <| Message.decode htmlDecoder message
    )


{-| Observe an HTML element that matches the selector provided to `Spec.Markup.query`.

    Spec.Markup.observeElement
      |> Spec.Markup.query << by [ attribute ("data-attr", "some-value") ]
      |> Spec.expect (Spec.Markup.hasText "something fun")

If the element cannot be found in the document, the claim will be rejected.
-}
observeElement : MarkupObservation HtmlElement
observeElement =
  MarkupObservation
    ( queryHtml
    , \selection message ->
        case Message.decode htmlDecoder message of
          Just element ->
            Ok element
          Nothing ->
            Err <| Report.fact "No element matches selector" (Selector.toString selection)
    )


{-| Observe all HTML elements that match the selector provided to `Spec.Markup.query`.

    Spec.Markup.observeElements
      |> Spec.Markup.query << by [ attribute ("data-attr", "some-value") ]
      |> Spec.expect (Spec.Claim.isListWithLength 3)

If no elements match the query, then the subject of the claim will be an empty list.
-}
observeElements : MarkupObservation (List HtmlElement)
observeElements =
  MarkupObservation
    ( queryAllHtml
    , \selection message ->
        Message.decode (Json.list htmlDecoder) message
          |> Maybe.withDefault []
          |> Ok
    )


{-| Search for HTML elements.

Use this function in conjunction with `observe`, `observeElement`, or `observeElements` to
observe the HTML document.
-}
query : (Selector Element, MarkupObservation a) -> Observer model a
query (selection, MarkupObservation (messageGenerator, handler)) =
  Observer.inquire (messageGenerator selection) (handler selection)
    |> Observer.observeResult
    |> Observer.mapRejection (
      Report.append <|
        Report.fact "Claim rejected for selector" <| Selector.toString selection
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
    |> Step.sendMessage


queryHtml : Selector Element -> Message
queryHtml selection =
  Message.for "_html" "query"
    |> Message.withBody (
      Encode.object [ ("selector", Encode.string <| Selector.toString selection) ]
    )


queryAllHtml : Selector Element -> Message
queryAllHtml selection =
  Message.for "_html" "queryAll"
    |> Message.withBody (
      Encode.object [ ("selector", Encode.string <| Selector.toString selection) ]
    )


{-| Represents an HTML element.
-}
type HtmlElement =
  HtmlElement HtmlElementData


type alias HtmlElementData =
  { tag: String
  , attributes: Dict String String
  , text: String
  }


htmlDecoder : Json.Decoder HtmlElement
htmlDecoder =
  Json.map HtmlElement <|
    Json.map3 HtmlElementData
      ( Json.field "tag" Json.string )
      ( Json.field "attributes" <| Json.dict Json.string )
      ( Json.field "textContext" Json.string )


{-| Claim that the text belonging to the HTML element contains the given text. 

Note that the text belonging to an observed HTML element includes the text
belonging to all its descendants.
-}
hasText : String -> Claim HtmlElement
hasText expectedText (HtmlElement element) =
  if String.contains expectedText element.text then
    Claim.Accept
  else
    Claim.Reject <| Report.batch
      [ Report.fact "Expected text" expectedText
      , Report.fact "but the actual text was" element.text
      ]


{-| Claim that the HTML element has the given attribute with the given value.

    Spec.Markup.observeElement
      |> Spec.Markup.query << by [ tag "div" ]
      |> Spec.expect (
        Spec.Markup.hasAttribute ("class", "red")
      )

-}
hasAttribute : ( String, String ) -> Claim HtmlElement
hasAttribute ( expectedName, expectedValue ) (HtmlElement element) =
  case Dict.get expectedName element.attributes of
    Just actualValue ->
      if expectedValue == actualValue then
        Claim.Accept
      else
        Claim.Reject <| Report.batch
          [ Report.fact "Expected element to have attribute" <| expectedName ++ " = " ++ expectedValue
          , Report.fact "but it has" <| expectedName ++ " = " ++ actualValue
          ]
    Nothing ->
      if Dict.isEmpty element.attributes then
        Claim.Reject <| Report.batch
          [ Report.fact "Expected element to have attribute" expectedName
          , Report.note "but it has no attributes"
          ]
      else
        Claim.Reject <| Report.batch
          [ Report.fact "Expected element to have attribute" expectedName
          , Report.fact "but it has only these attributes" <| attributeNames element.attributes
          ]


attributeNames : Dict String String -> String
attributeNames attributes =
  Dict.keys attributes
    |> String.join ", "
