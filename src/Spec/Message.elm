module Spec.Message exposing
  ( Message
  )

import Json.Encode exposing (Value)


type alias Message =
  { home: String
  , name: String
  , body: Value
  }
