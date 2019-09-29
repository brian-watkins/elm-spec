module Spec.Http.Route exposing
  ( HttpRoute
  , get
  )


type alias HttpRoute =
  { method: String
  , url: String
  }


get : String -> HttpRoute
get url =
  { method = "GET"
  , url = url
  }