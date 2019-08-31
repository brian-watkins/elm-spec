module Spec.Html.Selector exposing
  ( id
  , tag
  , attributeName
  , by
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


by : List Spec.Html.Selector -> a -> Spec.Html.Selection
by selectors _ =
  Spec.Html.By selectors
