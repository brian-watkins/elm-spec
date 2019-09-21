module Spec.Html.Selector exposing
  ( id
  , tag
  , attribute
  , attributeName
  , by
  , descendantsOf
  )

import Spec.Html


{-| Select Html elements by id.
-}
id : String -> Spec.Html.Selector
id =
  Spec.Html.Id


tag : String -> Spec.Html.Selector
tag =
  Spec.Html.Tag


attribute : (String, String) -> Spec.Html.Selector
attribute (name, value) =
  Spec.Html.Attribute name value


attributeName : String -> Spec.Html.Selector
attributeName =
  Spec.Html.AttributeName


by : List Spec.Html.Selector -> a -> (Spec.Html.Selection, a)
by selectors targetable =
  ( Spec.Html.By selectors, targetable )


descendantsOf : List Spec.Html.Selector -> (Spec.Html.Selection, a) -> (Spec.Html.Selection, a)
descendantsOf selectors ( selection, targetable )=
  ( Spec.Html.DescendantsOf selectors selection, targetable )