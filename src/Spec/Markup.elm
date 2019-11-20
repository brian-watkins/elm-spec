module Spec.Markup exposing
  ( MarkupObservation
  , observeTitle
  , observe
  , observeElement
  , observeElements
  , query
  , target
  , hasText
  , hasAttribute
  )

import Spec.Observer as Observer exposing (Observer)
import Spec.Claim as Claim exposing (Claim)
import Spec.Observation.Report as Report exposing (Report)
import Spec.Subject exposing (Subject)
import Spec.Markup.Selector as Selector exposing (Selection, Element)
import Spec.Step as Step
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json
import Dict exposing (Dict)


observeTitle : Observer model String
observeTitle =
  Observer.inquire selectTitleMessage <| \message ->
    Message.decode Json.string message
      |> Maybe.withDefault "FAILED"


selectTitleMessage : Message
selectTitleMessage =
  { home = "_html"
  , name = "application"
  , body = Encode.string "select-title"
  }


type MarkupObservation a =
  MarkupObservation
    (Selection Element -> Message, Selection Element -> Message -> Result Report a)


observe : MarkupObservation (Maybe HtmlElement)
observe =
  MarkupObservation
    ( queryHtml
    , \selection message ->
        Ok <| Message.decode htmlDecoder message
    )


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


observeElements : MarkupObservation (List HtmlElement)
observeElements =
  MarkupObservation
    ( queryAllHtml
    , \selection message ->
        Message.decode (Json.list htmlDecoder) message
          |> Maybe.withDefault []
          |> Ok
    )


query : (Selection Element, MarkupObservation a) -> Observer model a
query (selection, MarkupObservation (messageGenerator, handler)) =
  Observer.inquire (messageGenerator selection) (handler selection)
    |> Observer.observeResult
    |> Observer.mapRejection (
      Report.append <|
        Report.fact "Claim rejected for selector" <| Selector.toString selection
    )


target : (Selection a, Step.Context model) -> Step.Command msg
target (selection, context) =
  Step.sendMessage
    { home = "_html"
    , name = "target"
    , body = Encode.string <| Selector.toString selection
    }


queryHtml : Selection Element -> Message
queryHtml selection =
  { home = "_html"
  , name = "query"
  , body = Encode.object [ ("selector", Encode.string <| Selector.toString selection) ]
  }


queryAllHtml : Selection Element -> Message
queryAllHtml selection =
  { home = "_html"
  , name = "queryAll"
  , body = Encode.object [ ("selector", Encode.string <| Selector.toString selection) ]
  }


type HtmlNode
  = Element HtmlElement
  | Text String


type alias HtmlElement =
  { tag: String
  , attributes: Dict String String
  , children: List HtmlNode
  }


emptyElement : HtmlElement
emptyElement =
  { tag = ""
  , attributes = Dict.empty
  , children = []
  }


htmlDecoder : Json.Decoder HtmlElement
htmlDecoder =
  Json.map3 HtmlElement
    ( Json.field "tag" Json.string )
    ( Json.field "attributes" <| Json.dict Json.string )
    ( Json.field "children" <| Json.list <| 
      Json.oneOf
        [ Json.map Text <| Json.field "text" Json.string
        , Json.map Element <| Json.lazy (\_ -> htmlDecoder)
        ]
    )


hasText : String -> Claim HtmlElement
hasText expectedText element =
  if String.contains expectedText <| flattenTexts element.children then
    Claim.Accept
  else
    Claim.Reject <| Report.batch
      [ Report.fact "Expected text" expectedText
      , Report.fact "but the actual text was" <| flattenTexts element.children
      ]


hasAttribute : ( String, String ) -> Claim HtmlElement
hasAttribute ( expectedName, expectedValue ) element =
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


flattenTexts : List HtmlNode -> String
flattenTexts children =
  children
    |> List.map (\child ->
      case child of
        Element n ->
          flattenTexts n.children
        Text text ->
          text
    )
    |> String.join " "
