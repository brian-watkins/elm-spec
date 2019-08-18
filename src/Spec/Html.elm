module Spec.Html exposing
  ( Selector(..)
  , Selection(..)
  , select
  , target
  , expect
  , hasText
  )

import Spec.Observer as Observer exposing (Observer)
import Spec.Subject exposing (Subject)
import Spec.Context exposing (Context)
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


type Selector =
  Selector String


type Selection
  = By (List Selector)


target : Selection -> Message
target selection =
  { home = "_html"
  , name = "target"
  , body = Encode.string <| toString selection
  }


select : Selection -> Selector
select =
  Selector << toString


toString : Selection -> String
toString selection =
  case selection of
    By selectors ->
      List.map (\(Selector sel) -> sel) selectors
        |> String.join ""


selectHtml : Selector -> Message
selectHtml (Selector selector) =
  { home = "_html"
  , name = "select"
  , body = Encode.object [ ("selector", Encode.string selector) ]
  }


expect : Observer HtmlElement -> (() -> Selector) -> Observer (Context model)
expect observer selectorGenerator context =
  context.inquiries
    |> List.filter (Message.is "_html" "selected")
    |> List.head
    |> Maybe.andThen (Message.decode htmlDecoder)
    |> Maybe.map observer
    |> Maybe.withDefault (Observer.Inquire <| selectHtml (selectorGenerator ()))


type HtmlNode
  = Element HtmlElement
  | Text String


type alias HtmlElement =
  { tag: String
  , children: List HtmlNode
  }


htmlDecoder : Json.Decoder HtmlElement
htmlDecoder =
  Json.map2 HtmlElement
    ( Json.field "tag" Json.string )
    ( Json.field "children" <| Json.list <| 
      Json.oneOf
        [ Json.map Text <| Json.field "text" Json.string
        , Json.map Element <| Json.lazy (\_ -> htmlDecoder)
        ]
    )


hasText : String -> Observer HtmlElement
hasText expectedText element =
  if List.member expectedText <| flattenTexts element.children then
    Observer.accept
  else
    Observer.reject <| "Expected text\n\t" ++ expectedText ++ "\nbut the actual text was\n\t" ++ (String.join ", " (flattenTexts element.children))


flattenTexts : List HtmlNode -> List String
flattenTexts children =
  children
    |> List.map (\child ->
      case child of
        Element n ->
          flattenTexts n.children
        Text text ->
          [ text ]
    )
    |> List.concat
