module Spec.Html exposing
  ( Selector(..)
  , Selection(..)
  , select
  , target
  , expectElement
  , expectElements
  , hasText
  , hasAttribute
  )

import Spec.Observation as Observation exposing (Expectation)
import Spec.Observer as Observer exposing (Observer)
import Spec.Observation.Report as Report
import Spec.Subject exposing (Subject)
import Spec.Step as Step
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json
import Dict exposing (Dict)


type Selector
  = Id String
  | Tag String
  | AttributeName String
  | Attribute String String


type Selection
  = By (List Selector)
  | DescendantsOf (List Selector) Selection


target : (Selection, Step.Context model) -> Step.Command msg
target (selection, context) =
  Step.sendMessage
    { home = "_html"
    , name = "target"
    , body = Encode.string <| toString selection
    }


select : (Selection, ()) -> Selection
select (selection, _)=
  selection


toString : Selection -> String
toString selection =
  case selection of
    By selectors ->
      selectorString selectors
    DescendantsOf selectors next ->
      selectorString selectors ++ " " ++ toString next


selectorString : List Selector -> String
selectorString selectors =
  firstTagSelector selectors
    |> anyOtherSelectors selectors


firstTagSelector : List Selector -> String
firstTagSelector selectors =
  selectors
    |> List.filterMap (\selector -> 
      case selector of
        Tag name ->
          Just name
        _ ->
          Nothing
    )
    |> List.head
    |> Maybe.withDefault ""


anyOtherSelectors : List Selector -> String -> String
anyOtherSelectors selectors selString =
  selectors
    |> List.foldl (\selector output ->
      case selector of
        Id name ->
          output ++ "#" ++ name
        AttributeName name ->
          output ++ "[" ++ name ++ "]"
        Attribute name value ->
          output ++ "[" ++ name ++ "='" ++ value ++ "']"
        _ ->
          output  
    ) selString


selectHtml : Selection -> Message
selectHtml selection =
  { home = "_html"
  , name = "select"
  , body = Encode.object [ ("selector", Encode.string <| toString selection) ]
  }


selectAllHtml : Selection -> Message
selectAllHtml selection =
  { home = "_html"
  , name = "selectAll"
  , body = Encode.object [ ("selector", Encode.string <| toString selection) ]
  }


expectElement : Observer HtmlElement -> (() -> Selection) -> Expectation model
expectElement observer selectionGenerator =
  let
    selection = selectionGenerator ()
  in
    Observation.inquire (selectHtml selection)
      |> Observation.mapSelection (Message.decode htmlDecoder)
      |> Observation.expect (\maybeElement ->
        case maybeElement of
          Just element ->
            observer element
          Nothing ->
            Observer.Reject <| Report.fact "No element matches selector" (toString selection)
      )


expectElements : Observer (List HtmlElement) -> (() -> Selection) -> Expectation model
expectElements observer selectionGenerator =
  Observation.inquire (selectAllHtml <| selectionGenerator ())
    |> Observation.mapSelection (Message.decode <| Json.list htmlDecoder)
    |> Observation.mapSelection (Maybe.withDefault [])
    |> Observation.expect observer


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
