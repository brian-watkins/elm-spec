module Spec.Http exposing
  ( HttpRequest
  , RequestBody
  , observeRequests
  , header
  , stringBody
  , jsonBody
  , queryParameter
  )

{-| Observe, and make claims about HTTP requests during a spec.

Here's an example:

First, create an `HttpResponseStub` that defines the response to return when a request is sent by the program.

    successStub : HttpResponseStub
    successStub =
      Spec.Http.Stub.for (Spec.Http.Route.post "http://fake-api.com/api/sports")
        |> Spec.Http.Stub.withStatus 201

Now, you could write a spec that checks to see if the request body contains a value:

    Spec.describe "some request"
    [ Spec.scenario "the post is successful" (
        Spec.given (
          Spec.Setup.init (App.init testFlags)
            |> Spec.Setup.withView App.view
            |> Spec.Setup.withUpdate App.update
            |> Spec.Http.Stub.serve [ successStub ]
        )
        |> Spec.when "the request is sent"
          [ Spec.Markup.target << by [ id "request-button" ]
          , Spec.Markup.Event.click
          ]
        |> Spec.it "sends the correct request" (
          Spec.Http.observeRequests
              (Spec.Http.Route.post "http://fake-api.com/api/sports")
            |> Spec.expect (Spec.Claim.isListWhere
              [ Spec.Http.jsonBody
                  (Json.field "name" Json.string)
                  (Spec.Claim.isEqual Debug.toString "bowling")
              ]
            )
        )
      )
    ]

# Observe HTTP Requests
@docs HttpRequest, RequestBody, observeRequests

# Make Claims About HTTP Requests
@docs stringBody, jsonBody, header

# Make Claims about an HTTP Request's Route
@docs queryParameter

-}

import Spec.Observer as Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Claim as Claim exposing (Claim)
import Spec.Report as Report
import Spec.Message as Message exposing (Message)
import Spec.Http.Route as Route exposing (HttpRoute)
import Json.Decode as Json
import Dict exposing (Dict)
import Url exposing (Url)
import Url.Parser
import Url.Parser.Query




{-| Represents an HTTP request made by the program in the course of the scenario.
-}
type alias HttpRequest =
  { url: String
  , headers: Dict String String
  , body: RequestBody
  }


{-| Represents the body of an HTTP request.
-}
type RequestBody
  = EmptyBody
  | StringBody String


{-| Claim that an HTTP request has a header that satisfies the given claim.

For example, if the observed request has an `Authorization` header with the value
`Bearer some-fun-token`, then the following claim:

    Spec.Http.header "Authorization" <|
      Spec.Claim.isSomethingWhere <|
      Spec.Claim.isStringContaining 1 "some-fun-token"

would be accepted.

-}
header : String -> Claim (Maybe String) -> Claim HttpRequest
header name claim =
  \request ->
    Dict.get name request.headers
      |> claim
      |> Claim.mapRejection (\report -> Report.batch
        [ Report.fact "Claim rejected for header" name
        , report
        , Report.fact "The request actually had these headers" <| headerList request
        ]
      )

headerList : HttpRequest -> String
headerList request =
  Dict.toList request.headers
    |> List.map (\(k, v) -> k ++ " = " ++ v)
    |> String.join "\n"


{-| Claim that the body of an HTTP request is a string that satisfies the given claim.

Note: If you create a request with `Http.emptyBody` then the given claim will be evaluated
against the empty string.
-}
stringBody : Claim String -> Claim HttpRequest
stringBody claim =
  \request ->
    case request.body of
      EmptyBody ->
        evaluateStringBodyClaim claim ""
      StringBody actual ->
        evaluateStringBodyClaim claim actual


evaluateStringBodyClaim : Claim String -> String -> Claim.Verdict
evaluateStringBodyClaim claim body =
  claim body
    |> Claim.mapRejection (\report -> Report.batch
      [ Report.note "Claim rejected for string body"
      , report
      ]
    )


{-| Claim that the body of an HTTP request is a string that can be decoded with the
given decoder into a value that satisfies the given claim.

For example, if the body of the observed request was `{"sport":"bowling"}`, then the following claim:

    Spec.Http.jsonBody
      (Json.Decode.field "sport" Json.Decode.string)
      (Spec.Claim.isEqualTo Debug.toString "bowling")

would be accepted.

-}
jsonBody : Json.Decoder a -> Claim a -> Claim HttpRequest
jsonBody decoder claim =
  \request ->
    case request.body of
      EmptyBody ->
        Claim.Reject <| Report.batch
          [ Report.note "Expected to decode request body as JSON"
          , Report.note "but it has no body at all"
          ]
      StringBody actual ->
        case Json.decodeString decoder actual of
          Ok value ->
            claim value
          Err error ->
            Claim.Reject <| Report.batch
              [ Report.fact "Expected to decode request body as JSON" actual
              , Report.fact "but the decoder failed" <| Json.errorToString error
              ]


{-| Observe HTTP requests that match the given route.

For example:

    Spec.Http.observeRequests (Spec.Http.Route.get "http://fake.com/fake")
      |> Spec.expect (Spec.Claim.isListWhere
        [ Spec.Http.header "Authorization" <|
            Spec.Claim.isSomethingWhere <|
            Spec.Claim.isStringContaining 1 "some-fun-token"
        ]
      )

-}
observeRequests : HttpRoute -> Observer model (List HttpRequest)
observeRequests route =
  Observer.inquire (fetchRequestsFor route) (
    Message.decode (Json.list requestDecoder)
      >> Maybe.withDefault []
  )
  |> Observer.mapRejection (\report ->
    Report.batch
    [ Report.fact  "Claim rejected for route" <| Route.toString route
    , report
    ]
  )


fetchRequestsFor : HttpRoute -> Message
fetchRequestsFor route =
  Message.for "_http" "fetch-requests"
    |> Message.withBody (
      Route.encode route
    )


requestDecoder : Json.Decoder HttpRequest
requestDecoder =
  Json.map3 HttpRequest
    ( Json.field "url" Json.string )
    ( Json.field "headers" <| Json.dict Json.string )
    ( Json.field "body" requestBodyDecoder )


requestBodyDecoder : Json.Decoder RequestBody
requestBodyDecoder =
  Json.nullable Json.string
    |> Json.map (
      Maybe.map StringBody
        >> Maybe.withDefault EmptyBody
    )


{-| Claim that a query parameter has a value that satisfies the given claim.

For example, if a request is made to `http://fun.com/fun?activity=bowling`,
then the following claim would be satisfied:

    Spec.Http.observeRequests (Spec.Http.Route.get "http://fun.com/fun" |> Spec.Http.Route.withAnyQuery)
      |> Spec.expect (Spec.Claim.isListWhere
        [ Spec.Http.queryParameter "actvity" <|
            Spec.Claim.isEqual Debug.toString "bowling"
        ]
      )

-}
queryParameter : String -> Claim (List String) -> Claim HttpRequest
queryParameter name claim =
  \request ->
    case Url.fromString request.url of
      Just url ->
        queryParameterValues name url
          |> claim
          |> Claim.mapRejection (\report -> Report.batch
            [ Report.fact "Claim rejected for query parameter" name
            , report
            ]
          )
      Nothing ->
        Claim.Reject <| Report.fact "Unable to parse URL" request.url


queryParameterValues : String -> Url -> List String
queryParameterValues param url =
  { url | path = "" }
    |> Url.Parser.parse (Url.Parser.query <| Url.Parser.Query.custom param identity) 
    |> Maybe.withDefault []

