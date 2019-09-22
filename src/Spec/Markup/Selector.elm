module Spec.Markup.Selector exposing
  ( Selector
  , Selection
  , select
  , target
  , id
  , tag
  , attribute
  , attributeName
  , by
  , descendantsOf
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


by : List Selector -> a -> (Selection, a)
by selectors targetable =
  ( By selectors, targetable )


descendantsOf : List Selector -> (Selection, a) -> (Selection, a)
descendantsOf selectors ( selection, targetable )=
  ( DescendantsOf selectors selection, targetable )


toString : Selection -> String
toString selection =
  case selection of
    By selectors ->
      selectorString selectors
    DescendantsOf selectors next ->
      selectorString selectors ++ " " ++ toString next


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
