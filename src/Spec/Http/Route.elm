module Spec.Http.Route exposing
  ( HttpRoute
  , get
  , post
  , route
  )


type alias HttpRoute =
  { method: String
  , url: String
  }


get : String -> HttpRoute
get =
  route "GET"


post : String -> HttpRoute
post =
  route "POST"


route : String -> String -> HttpRoute
route method url =
  { method = method
  , url = url
  }