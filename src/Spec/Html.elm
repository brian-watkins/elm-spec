module Spec.Html exposing
  ( target
  , expect
  , hasText
  )

import Spec.Observer as Observer exposing (Observer)
import Spec.Context exposing (Context)
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


type alias HtmlSelector =
  { selector: String
  }


target : String -> HtmlSelector
target id =
  { selector = id
  }


selectHtml : HtmlSelector -> Message
selectHtml selector =
  { home = "_html"
  , name = "select"
  , body = Encode.object [ ("selector", Encode.string selector.selector) ]
  }


expect : Observer HtmlElement -> HtmlSelector -> Observer (Context model)
expect observer selector context =
  context.inquiries
    |> List.filter (Message.is "_html" "selected")
    |> List.head
    |> Maybe.andThen (Message.decode htmlDecoder)
    |> Maybe.map observer
    |> Maybe.withDefault (Observer.Inquire <| selectHtml selector)


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
