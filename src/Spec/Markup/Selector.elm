module Spec.Markup.Selector exposing
  ( Selector
  , Selection
  , Element
  , Object
  , target
  , id
  , tag
  , attribute
  , attributeName
  , by
  , descendantsOf
  , document
  , toString
  )

import Json.Encode as Encode
import Spec.Step as Step
import Spec.Message exposing (Message)


type Selector
  = Id String
  | Tag String
  | AttributeName String
  | Attribute String String


type Selection a
  = By (List Selector)
  | DescendantsOf (List Selector) (Selection a)
  | Document


type Element
  = Element


type Object
  = Object


target : (Selection a, Step.Context model) -> Step.Command msg
target (selection, context) =
  Step.sendMessage
    { home = "_html"
    , name = "target"
    , body = Encode.string <| toString selection
    }


{-| Select Html elements by id.
-}
id : String -> Selector
id =
  Id


tag : String -> Selector
tag =
  Tag


attribute : (String, String) -> Selector
attribute (name, value) =
  Attribute name value


attributeName : String -> Selector
attributeName =
  AttributeName


by : List Selector -> a -> (Selection Element, a)
by selectors targetable =
  ( By selectors, targetable )


descendantsOf : List Selector -> (Selection Element, a) -> (Selection Element, a)
descendantsOf selectors ( selection, targetable )=
  ( DescendantsOf selectors selection, targetable )


document : Step.Context model -> (Selection Object, Step.Context model)
document context =
  ( Document, context )


toString : Selection a -> String
toString selection =
  case selection of
    By selectors ->
      selectorString selectors
    DescendantsOf selectors next ->
      selectorString selectors ++ " " ++ toString next
    Document ->
      "_document_"


--- Private


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
