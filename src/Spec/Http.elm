module Spec.Http exposing
  ( HttpRequest
  , RequestBody
  , observeRequests
  , hasHeader
  , hasStringBody
  , hasJsonBody
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
              [ Spec.Http.hasJsonBody
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
@docs hasHeader, hasStringBody, hasJsonBody

-}

import Spec.Observer as Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Claim as Claim exposing (Claim)
import Spec.Report as Report
import Spec.Message as Message exposing (Message)
import Spec.Http.Route exposing (HttpRoute)
import Json.Encode as Encode
import Json.Decode as Json
import Dict exposing (Dict)




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


{-| Claim that an HTTP request has a header with the given (key, value) tuple.

For example, if the observed request has an `Authorization` header with the value
`Bearer some-fun-token`, then the following claim:

    Spec.Http.hasHeader ("Authorization", "Bearer some-fun-token")

would be accepted.

-}
hasHeader : (String, String) -> Claim HttpRequest
hasHeader ( expectedName, expectedValue ) =
  \request ->
    case Dict.get expectedName request.headers of
      Just actualValue ->
        if actualValue == expectedValue then
          Claim.Accept
        else
          rejectRequestForHeader (expectedName, expectedValue) request
      Nothing ->
        rejectRequestForHeader (expectedName, expectedValue) request


rejectRequestForHeader : (String, String) -> HttpRequest -> Claim.Verdict
rejectRequestForHeader ( expectedName, expectedValue ) request =
  Claim.Reject <| Report.batch
    [ Report.fact "Expected request to have header" <| expectedName ++ " = " ++ expectedValue
    , Report.fact "but it has" <| String.join "\n" <| List.map (\(k, v) -> k ++ " = " ++ v) <| Dict.toList request.headers
    ]


{-| Claim that the body of an HTTP request is a string that is equal to the given value.
-}
hasStringBody : String -> Claim HttpRequest
hasStringBody expected =
  \request ->
    case request.body of
      EmptyBody ->
        Claim.Reject <| Report.batch
          [ Report.fact "Expected request to have body with string" expected
          , Report.note "but it has no body at all"
          ]
      StringBody actual ->
        if actual == expected then
          Claim.Accept
        else
          Claim.Reject <| Report.batch
            [ Report.fact "Expected request to have body with string" expected
            , Report.fact "but it has" actual
            ]


{-| Claim that the body of an HTTP request is a string that can be decoded with the
given decoder into a value that satisfies the given claim.

For example, if the body of the observed request was `{"sport":"bowling"}`, then the following claim:

    Spec.Http.hasJsonBody
      (Json.Decode.field "sport" Json.Decode.string)
      (Spec.Claim.isEqualTo Debug.toString "bowling")

would be accepted.

-}
hasJsonBody : Json.Decoder a -> Claim a -> Claim HttpRequest
hasJsonBody decoder claim =
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
      |> Spec.expect (Spec.Claim.isList
        [ Spec.Http.hasHeader ("Authorization", "Bearer some-fun-token")
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
    [ Report.fact  "Claim rejected for route" <| route.method ++ " " ++ route.url
    , report
    ]
  )


fetchRequestsFor : HttpRoute -> Message
fetchRequestsFor route =
  Message.for "_http" "fetch-requests"
    |> Message.withBody (
      Encode.object
        [ ( "method", Encode.string route.method )
        , ( "url", Encode.string route.url )
        ]
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