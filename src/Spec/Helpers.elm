module Spec.Helpers exposing
  ( mapDocument
  )

import Browser exposing (Document)
import Html


mapDocument : (a -> b) -> Document a -> Document b
mapDocument mapper document =
  { title = document.title
  , body = List.map (Html.map mapper) document.body
  }