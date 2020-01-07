module Spec.Http.Route exposing
  ( HttpRoute
  , get
  , post
  , route
  , withAnyQuery
  , encode
  , toString
  )

{-| Functions for defining HTTP routes.

@docs HttpRoute

# Define a Route
@docs get, post, route, withAnyQuery

# Work with Routes
@docs encode, toString

-}

import Json.Encode as Encode


{-| An HTTP route is an HTTP method plus a URL.
-}
type HttpRoute =
  HttpRoute
    { method: String
    , url: String
    , query: QueryMatcher
    }


type QueryMatcher
  = None
  | Any


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
  HttpRoute
    { method = method
    , url = url
    , query = None
    }


{-| Specify that the route may have any query string (or none at all).

For example, if you write a scenario where there are multiple requests
to the same endpoint with different query parameters, then you could
observe requests with any query like so:

    Spec.Http.observeRequests (get "http://fake.com/fake" |> withAnyQuery)
      |> Spec.expect (Spec.Claim.isListWhere
        [ Spec.Http.queryParameter "page" <|
            Spec.Claim.isEqual Debug.toString "1"
        , Spec.Http.queryParameter "page" <|
            Spec.Claim.isEqual Debug.toString "2"
        ]
      )

-}
withAnyQuery : HttpRoute -> HttpRoute
withAnyQuery (HttpRoute routeData) =
  HttpRoute
    { routeData | query = Any }


{-| Encode an `HttpRoute` into a JSON object.
-}
encode : HttpRoute -> Encode.Value
encode (HttpRoute routeData) =
  Encode.object
    [ ( "method", Encode.string routeData.method )
    , ( "url", Encode.string routeData.url )
    , ( "query", Encode.object [ ( "type", encodeQueryMatcher routeData.query ) ] )
    ]


encodeQueryMatcher : QueryMatcher -> Encode.Value
encodeQueryMatcher queryMatcher =
  case queryMatcher of
    None ->
      Encode.string "NONE"
    Any ->
      Encode.string "ANY"


{-| Represent an `HttpRoute` as a string.
-}
toString : HttpRoute -> String
toString (HttpRoute routeData) =
  routeData.method ++ " " ++ routeData.url ++ (queryMatcherToString routeData.query)


queryMatcherToString : QueryMatcher -> String
queryMatcherToString queryMatcher =
  case queryMatcher of
    None ->
      ""
    Any ->
      "?*"