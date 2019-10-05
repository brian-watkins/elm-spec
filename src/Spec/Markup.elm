module Spec.Markup exposing
  ( expectElement
  , expectElements
  , expectAbsent
  , hasText
  , hasAttribute
  , selectTitle
  )

import Spec.Observation as Observation exposing (Expectation)
import Spec.Observer as Observer exposing (Observer)
import Spec.Observation.Report as Report
import Spec.Subject exposing (Subject)
import Spec.Markup.Selector as Selector exposing (Selection)
import Spec.Step as Step
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json
import Dict exposing (Dict)


selectTitle : Observation.Selection model String
selectTitle =
  Observation.inquire selectTitleMessage
    |> Observation.mapSelection (Message.decode Json.string)
    |> Observation.mapSelection (Maybe.withDefault "FAILED")


selectTitleMessage : Message
selectTitleMessage =
  { home = "_html"
  , name = "application"
  , body = Encode.string "select-title"
  }


expectElement : Observer HtmlElement -> (() -> Selection) -> Expectation model
expectElement observer selectionGenerator =
  let
    selection = selectionGenerator ()
  in
    observeSelection selection <|
      \maybeElement ->
        case maybeElement of
          Just element ->
            observer element
          Nothing ->
            Observer.Reject <| Report.fact "No element matches selector" (Selector.toString selection)


expectAbsent : (() -> Selection) -> Expectation model
expectAbsent selectionGenerator =
  let
    selection = selectionGenerator ()
  in
    observeSelection selection <|
      \maybeElement ->
        case maybeElement of
          Just _ ->
            Observer.Reject <| Report.batch
              [ Report.fact "Expected no elements to be selected with" <| Selector.toString selection
              , Report.note "but one or more elements were selected"
              ]
          Nothing ->
            Observer.Accept


observeSelection : Selection -> Observer (Maybe HtmlElement) -> Expectation model
observeSelection selection observer =
  Observation.inquire (selectHtml selection)
      |> Observation.mapSelection (Message.decode htmlDecoder)
      |> Observation.expect observer


expectElements : Observer (List HtmlElement) -> (() -> Selection) -> Expectation model
expectElements observer selectionGenerator =
  Observation.inquire (selectAllHtml <| selectionGenerator ())
    |> Observation.mapSelection (Message.decode <| Json.list htmlDecoder)
    |> Observation.mapSelection (Maybe.withDefault [])
    |> Observation.expect observer


selectHtml : Selection -> Message
selectHtml selection =
  { home = "_html"
  , name = "select"
  , body = Encode.object [ ("selector", Encode.string <| Selector.toString selection) ]
  }


selectAllHtml : Selection -> Message
selectAllHtml selection =
  { home = "_html"
  , name = "selectAll"
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


hasText : String -> Observer HtmlElement
hasText expectedText element =
  if String.contains expectedText <| flattenTexts element.children then
    Observer.Accept
  else
    Observer.Reject <| Report.batch
      [ Report.fact "Expected text" expectedText
      , Report.fact "but the actual text was" <| flattenTexts element.children
      ]


hasAttribute : ( String, String ) -> Observer HtmlElement
hasAttribute ( expectedName, expectedValue ) element =
  case Dict.get expectedName element.attributes of
    Just actualValue ->
      if expectedValue == actualValue then
        Observer.Accept
      else
        Observer.Reject <| Report.batch
          [ Report.fact "Expected element to have attribute" <| expectedName ++ " = " ++ expectedValue
          , Report.fact "but it has" <| expectedName ++ " = " ++ actualValue
          ]
    Nothing ->
      if Dict.isEmpty element.attributes then
        Observer.Reject <| Report.batch
          [ Report.fact "Expected element to have attribute" expectedName
          , Report.note "but it has no attributes"
          ]
      else
        Observer.Reject <| Report.batch
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
