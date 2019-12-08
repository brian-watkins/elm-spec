module Spec.Markup.Selector exposing
  ( Characteristic
  , Selector
  , Element
  , Object
  , id
  , tag
  , attribute
  , attributeName
  , by
  , descendantsOf
  , document
  , toString
  )

{-| Build abstract descriptions that can be used to select aspects of an HTML document.

# Build Selectors
@docs Selector, Element, by, descendantsOf, Object, document, toString

# Define Characteristics
@docs Characteristic, id, tag, attribute, attributeName

-}

import Json.Encode as Encode
import Spec.Step as Step
import Spec.Message exposing (Message)


{-| A selector is built from one or more characteristics. 
-}
type Characteristic
  = Id String
  | Tag String
  | AttributeName String
  | Attribute String String


{-| An abstract description of some aspect of an HTML document, usually an HTML element.
-}
type Selector a
  = By (List Characteristic)
  | DescendantsOf (List Characteristic) (Selector a)
  | Document


{-| A kind of selector that pertains only to HTML elements.
-}
type Element
  = Element


{-| A kind of selector that pertains only to a specific item.
-}
type Object
  = Object


{-| Generate a characteristic that belongs to elements having
an `id` attribute with the given value.
-}
id : String -> Characteristic
id =
  Id


{-| Generate a characteristic that belongs to elements having the given tag name.

For example,

    tag "div"

applies to HTML `<div>` elements.

-}
tag : String -> Characteristic
tag =
  Tag


{-| Generate a characteristic that belongs to elements with the given (name, value) pair.

For example,

    attribute ( "data-some-attr", "some-value" )

applies to elements having an attribute named `data-some-attr` with the value `some-value`.

-}
attribute : (String, String) -> Characteristic
attribute (name, value) =
  Attribute name value


{-| Generate a characteristic that belongs to elements with the given attribute.

For example, 

    attributeName "data-some-attr"

applies to elements having an attribute names `data-some-attr`.

-}
attributeName : String -> Characteristic
attributeName =
  AttributeName


{-| Generate a selector that matches HTML elements with the given characteristics.
-}
by : List Characteristic -> a -> (Selector Element, a)
by selectors targetable =
  ( By selectors, targetable )


{-| Generate a selector that matches HTML elements descending from any HTML elements with the
given characteristics.

For example,

    descendantsOf [ tag "div" ] << by [ tag "span" ]

will match all `<span>` that are inside a `<div>`.

-}
descendantsOf : List Characteristic -> (Selector Element, a) -> (Selector Element, a)
descendantsOf selectors ( selection, targetable )=
  ( DescendantsOf selectors selection, targetable )


{-| Generate a selector that matches the HTML document.

This is used primarily in conjunction with `Spec.Markup.target` to trigger
document-level events.

-}
document : Step.Context model -> (Selector Object, Step.Context model)
document context =
  ( Document, context )


{-| Convert a Selector to a string.

For those selectors of type `Selector Element`, the resulting string will be in
the style of a CSS selector.
-}
toString : Selector a -> String
toString selection =
  case selection of
    By selectors ->
      selectorString selectors
    DescendantsOf selectors next ->
      selectorString selectors ++ " " ++ toString next
    Document ->
      "_document_"


--- Private


selectorString : List Characteristic -> String
selectorString selectors =
  firstTagCharacteristic selectors
    |> anyOtherCharacteristics selectors


firstTagCharacteristic : List Characteristic -> String
firstTagCharacteristic selectors =
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


anyOtherCharacteristics : List Characteristic -> String -> String
anyOtherCharacteristics selectors selString =
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
