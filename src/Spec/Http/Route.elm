module Spec.Http.Route exposing
  ( HttpRoute
  , UrlDescriptor(..)
  , get
  , post
  , route
  , encode
  , toString
  )

{-| Functions for defining HTTP routes.

@docs HttpRoute

# Define a Route
@docs get, post, UrlDescriptor, route

# Work with Routes
@docs encode, toString

-}

import Json.Encode as Encode
import Url exposing (Protocol(..))


{-| Represents an HTTP route.
-}
type HttpRoute =
  HttpRoute
    { method: String
    , uri: UrlDescriptor
    }


{-| Define a GET route with the given URL.

    get "http://fun.com/fun"

-}
get : String -> HttpRoute
get =
  route "GET" << Exact


{-| Define a POST route with the given URL.

    post "http://fun.com/fun"

-}
post : String -> HttpRoute
post =
  route "POST" << Exact


{-| Describe a URL when constructing a Route with the `route` function.

Use the `Exact` case when you want to provide a specific string to match against, for example, an absolute URL.

Use the `Matching` case when you want to provide a JavaScript-style regular expression to match against.
-}
type UrlDescriptor
  = Exact String
  | Matching String


{-| Define a route with the given method and url descriptor.

For example, this route describes any request with the
protocol `http` and the method `PATCH`:

    Spec.Http.Route.route "PATCH" <|
      Matching "http:\\/\\/.+"

And this route describes any `GET` request to `http://someplace.com/api` with any value
for the query parameter `key` (and any additional query parameters):

    Spec.Http.Route.route "GET" <|
      Matching "http:\\/\\/someplace\\.com\\/api\\?key=.+"

-}
route : String -> UrlDescriptor -> HttpRoute
route method urlDescriptor =
  HttpRoute
    { method = method
    , uri = urlDescriptor
    }


{-| Encode an `HttpRoute` into a JSON object.
-}
encode : HttpRoute -> Encode.Value
encode (HttpRoute routeData) =
  Encode.object
    [ ( "method", Encode.string routeData.method )
    , ( "uri", encodeUri routeData.uri )
    ]


encodeUri : UrlDescriptor -> Encode.Value
encodeUri urlDescriptor =
  case urlDescriptor of
    Exact uri ->
      Encode.object
        [ ("type", Encode.string "EXACT")
        , ("value", Encode.string uri)
        ]
    Matching regex ->
      Encode.object
        [ ("type", Encode.string "REGEXP")
        , ("value", Encode.string regex)
        ]


{-| Represent an `HttpRoute` as a string.
-}
toString : HttpRoute -> String
toString (HttpRoute routeData) =
  routeData.method ++ " " ++ uriToString routeData.uri


uriToString : UrlDescriptor -> String
uriToString urlDescriptor =
  case urlDescriptor of
    Exact uri ->
      uri
    Matching regex ->
      "/" ++ regex ++ "/"
