module Spec.Http.Route exposing
  ( HttpRoute
  , get
  , post
  , route
  )

{-| Functions for defining HTTP routes.

@docs HttpRoute

# Define a Route
@docs get, post, route

-}


{-| An HTTP route is an HTTP method plus a URL.
-}
type alias HttpRoute =
  { method: String
  , url: String
  }


{-| Define a GET route.
-}
get : String -> HttpRoute
get =
  route "GET"


{-| Define a POST route.
-}
post : String -> HttpRoute
post =
  route "POST"


{-| Define a route with the given method and url.

    Spec.Http.Route.route "PATCH" "http://fake-server.com/fake"

-}
route : String -> String -> HttpRoute
route method url =
  { method = method
  , url = url
  }