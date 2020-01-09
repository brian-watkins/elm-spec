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
import Url exposing (Url, Protocol(..))


{-| An HTTP route is an HTTP method plus a URL.
-}
type HttpRoute =
  HttpRoute
    { method: String
    , origin: String
    , path: String
    , query: QueryMatcher
    }


type QueryMatcher
  = None
  | Exact String
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
route method urlString =
  case Url.fromString urlString of
    Just url ->
      HttpRoute
        { method = method
        , origin = originFrom url
        , path = url.path
        , query =
            url.query
              |> Maybe.map Exact
              |> Maybe.withDefault None
        }
    Nothing ->
      HttpRoute
        { method = method
        , origin = ""
        , path = urlString
        , query = None
        }


originFrom : Url -> String
originFrom url =
  [ protocolFrom url
  , url.host
  , portFrom url
  ]
    |> String.join ""


protocolFrom : Url -> String
protocolFrom url =
  case url.protocol of
    Http ->
      "http://"
    Https ->
      "https://"


portFrom : Url -> String
portFrom url =
  url.port_
    |> Maybe.map (\p -> ":" ++ String.fromInt p)
    |> Maybe.withDefault ""


{-| Specify that the route must have some query string
(but it doesn't matter what it is).

For example, if you write a scenario where there are multiple requests
to the same endpoint with different query parameters, then you could
observe requests that have some query (it doesn't matter what it is) like so:

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
    , ( "origin", Encode.string routeData.origin )
    , ( "path", Encode.string routeData.path )
    , ( "query", encodeQueryMatcher routeData.query )
    ]


encodeQueryMatcher : QueryMatcher -> Encode.Value
encodeQueryMatcher queryMatcher =
  case queryMatcher of
    None ->
      Encode.object
        [ ("type", Encode.string "NONE")
        ]
    Exact query ->
      Encode.object
        [ ("type", Encode.string "EXACT")
        , ("value", Encode.string query)
        ]
    Any ->
      Encode.object
        [ ("type", Encode.string "ANY")
        ]


{-| Represent an `HttpRoute` as a string.
-}
toString : HttpRoute -> String
toString (HttpRoute routeData) =
  routeData.method ++ " " ++ routeData.origin ++ routeData.path ++ (queryMatcherToString routeData.query)


queryMatcherToString : QueryMatcher -> String
queryMatcherToString queryMatcher =
  case queryMatcher of
    None ->
      ""
    Exact query ->
      "?" ++ query
    Any ->
      "?*"