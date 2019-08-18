module Spec.Html.Selector exposing
  ( id
  , by
  )

import Spec.Html


{-| Select Html elements by id.
-}
id : String -> Spec.Html.Selector
id expectedId =
  Spec.Html.Selector <| "#" ++ expectedId


by : List Spec.Html.Selector -> a -> Spec.Html.Selection
by selectors _ =
  Spec.Html.By selectors
