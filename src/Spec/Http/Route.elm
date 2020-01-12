module Spec.Http.Route exposing
  ( HttpRoute
  , get
  , post
  , route
  , PathComponent(..)
  , withPath
  , withAnyOrigin
  , withAnyQuery
  , encode
  , toString
  )

{-| Functions for defining HTTP routes.

@docs HttpRoute

# Define a Route
@docs get, post, route, withAnyOrigin, withAnyQuery, PathComponent, withPath

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
    , origin: RoutePart
    , path: List PathComponent
    , query: RoutePart
    }


{-| Define a segment of a path.

Use this type in conjunction with `Spec.Http.Route.withPath` to define a path.
-}
type PathComponent
  = Segment String
  | Variable String


type RoutePart
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
        , path = pathFrom url
        , query = queryFrom url
        }
    Nothing ->
      if String.startsWith "/" urlString then
        routeFromPath method urlString
      else
        HttpRoute
          { method = method
          , origin = None
          , path = []
          , query = None
          }


routeFromPath : String -> String -> HttpRoute
routeFromPath method path =
  case Url.fromString <| "http://localhost" ++ path of
    Just url ->
      HttpRoute
        { method = method
        , origin = None
        , path = pathFrom url
        , query = queryFrom url
        }
    Nothing ->
      HttpRoute
        { method = method
        , origin = None
        , path = []
        , query = None
        }


pathFrom : Url -> List PathComponent
pathFrom url =
  url.path
    |> String.dropLeft 1
    |> String.split "/"
    |> List.filter (not << String.isEmpty)
    |> List.map Segment


originFrom : Url -> RoutePart
originFrom url =
  Exact <|
    String.join ""
      [ protocolFrom url
      , url.host
      , portFrom url
      ]


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


queryFrom : Url -> RoutePart
queryFrom url =
  url.query
    |> Maybe.map Exact
    |> Maybe.withDefault None


{-| Specify the route's path.

Use this function to specify the route when you want to observe path variables.

    Spec.Http.observeRequests (
      get "http://fun.com"
        |> withPath
          [ Exactly "books"
          , VariableNamed "id"
          ]
    )
      |> Spec.expect (Spec.Claim.isListWhere
        [ Spec.Http.pathVariable "id" <|
            Spec.Claim.isEqual Debug.toString "27"
        ]
      )
-}
withPath : List PathComponent -> HttpRoute -> HttpRoute
withPath components (HttpRoute routeData) =
  HttpRoute
    { routeData | path = components }


{-| Specify that the route must have some origin (but it doesn't matter what it is).

For example, you could write a stub that matches any requests with some path,
regardless of their origin, like so:

    anyOriginStub =
      Spec.Http.Stub.for (get "/some/cool/path" |> withAnyOrigin)
        |> Spec.Http.Stub.withBody "{}"

A request to `http://fun-place.com/some/cool/path` would be matched by this stub
but a request to `/some/cool/path` (ie without any origin) would not.

-}
withAnyOrigin : HttpRoute -> HttpRoute
withAnyOrigin (HttpRoute routeData) =
  HttpRoute
    { routeData | origin = Any }


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
    , ( "origin", encodeRoutePart routeData.origin )
    , ( "path", Encode.list encodePathComponent routeData.path )
    , ( "query", encodeRoutePart routeData.query )
    ]


encodePathComponent : PathComponent -> Encode.Value
encodePathComponent component =
  case component of
    Segment segment ->
      Encode.object
        [ ("type", Encode.string "EXACT")
        , ("value", Encode.string segment)
        ]
    Variable name ->
      Encode.object
        [ ("type", Encode.string "VARIABLE")
        , ("value", Encode.string name)
        ]


encodeRoutePart : RoutePart -> Encode.Value
encodeRoutePart routePart =
  case routePart of
    None ->
      Encode.object
        [ ("type", Encode.string "NONE")
        ]
    Exact part ->
      Encode.object
        [ ("type", Encode.string "EXACT")
        , ("value", Encode.string part)
        ]
    Any ->
      Encode.object
        [ ("type", Encode.string "ANY")
        ]


{-| Represent an `HttpRoute` as a string.
-}
toString : HttpRoute -> String
toString (HttpRoute routeData) =
  routeData.method ++ " "
    ++ (originPartToString routeData.origin)
    ++ (List.map pathComponentToString routeData.path |> String.join "")
    ++ (queryPartToString routeData.query)


originPartToString : RoutePart -> String
originPartToString routePart =
  case routePart of
    None ->
      ""
    Exact part ->
      part
    Any ->
      "*"


pathComponentToString : PathComponent -> String
pathComponentToString component =
  case component of
    Segment segment ->
      "/" ++ segment
    Variable name ->
      "/:" ++ name


queryPartToString : RoutePart -> String
queryPartToString routePart =
  case routePart of
    None ->
      ""
    Exact query ->
      "?" ++ query
    Any ->
      "?*"