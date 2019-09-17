module Spec.Html.Selector exposing
  ( id
  , tag
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


attributeName : String -> Spec.Html.Selector
attributeName =
  Spec.Html.AttributeName


by : List Spec.Html.Selector -> a -> (Spec.Html.Selection, a)
by selectors targetable =
  ( Spec.Html.By selectors, targetable )


descendantsOf : List Spec.Html.Selector -> (Spec.Html.Selection, a) -> (Spec.Html.Selection, a)
descendantsOf selectors ( selection, targetable )=
  ( Spec.Html.DescendantsOf selectors selection, targetable )