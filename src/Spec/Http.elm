module Spec.Http exposing
  ( HttpRequest
  , log
  , observeRequests
  , clearRequestHistory
  , header
  , stringBody
  , jsonBody
  , url
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
@docs HttpRequest, observeRequests, clearRequestHistory, log

# Make Claims About HTTP Requests
@docs url, header, stringBody, jsonBody

-}

import Spec.Observer as Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Claim as Claim exposing (Claim)
import Spec.Report as Report exposing (Report)
import Spec.Message as Message exposing (Message)
import Spec.Http.Route as Route exposing (HttpRoute)
import Spec.Step as Step
import Spec.Step.Command as Command
import Json.Decode as Json
import Dict exposing (Dict)
import Url exposing (Url)
import Url.Parser
import Url.Parser.Query




{-| Represents an HTTP request made by the program in the course of the scenario.
-}
type HttpRequest
  = HttpRequest RequestData


type alias RequestData =
  { method: String
  , url: String
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
`Bearer some-fun-token`, then the following claim would be accepted:

    Spec.Http.header "Authorization" <|
      Spec.Claim.isSomethingWhere <|
      Spec.Claim.isStringContaining 1 "some-fun-token"

-}
header : String -> Claim (Maybe String) -> Claim HttpRequest
header name claim =
  \(HttpRequest request) ->
    Dict.get name request.headers
      |> claim
      |> Claim.mapRejection (\report -> Report.batch
        [ Report.fact "Claim rejected for header" name
        , report
        , Report.fact "The request actually had these headers" <| headerList request
        ]
      )

headerList : RequestData -> String
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
  \(HttpRequest request) ->
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

For example, if the body of the observed request was `{"sport":"bowling"}`,
then the following claim would be accepted:

    Spec.Http.jsonBody
      (Json.Decode.field "sport" Json.Decode.string)
      (Spec.Claim.isEqualTo Debug.toString "bowling")

-}
jsonBody : Json.Decoder a -> Claim a -> Claim HttpRequest
jsonBody decoder claim =
  \(HttpRequest request) ->
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
      >> Result.withDefault []
  )
  |> Observer.mapRejection (\report ->
    Report.batch
    [ Report.fact "Claim rejected for route" <| Route.toString route
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
  Json.map4 RequestData
    ( Json.field "methpd" Json.string )
    ( Json.field "url" Json.string )
    ( Json.field "headers" <| Json.dict Json.string )
    ( Json.field "body" requestBodyDecoder )
  |> Json.map HttpRequest


requestBodyDecoder : Json.Decoder RequestBody
requestBodyDecoder =
  Json.nullable Json.string
    |> Json.map (
      Maybe.map StringBody
        >> Maybe.withDefault EmptyBody
    )


{-| A step that clears the history of HTTP requests received.

Any HTTP requests made prior to executing this step will not be observed.

It can be useful to clear the HTTP request history when a scenario results in
many HTTP requests, but you care about observing only those that occur
after a certain point.
-}
clearRequestHistory : Step.Context model -> Step.Command msg
clearRequestHistory _ =
  Command.sendMessage <| Message.for "_http" "clear-history"


{-| A step that logs to the console any HTTP requests received prior to executing this step.

You might use this step to help debug a rejected observation.
-}
log : Step.Context model -> Step.Command msg
log _ =
  fetchRequestsFor (Route.route "ANY" <| Route.Matching ".+")
    |> Command.sendRequest logRequests


logRequests : Message -> Step.Command msg
logRequests message =
  Message.decode (Json.list requestDecoder) message
    |> Result.map (Command.log << requestReport)
    |> Result.withDefault (Command.log <| Report.note "Unable to decode HTTP requests!")


requestReport : List HttpRequest -> Report
requestReport requests =
  if List.isEmpty requests then
    Report.note "No HTTP requests received"
  else
    List.map (\(HttpRequest data) -> requestDataToString data) requests
      |> String.join "\n"
      |> Report.fact "HTTP requests received"


requestDataToString : RequestData -> String
requestDataToString data =
  data.method ++ " " ++ data.url


{-| Claim that the url of an HTTP request satisfies the given claim.

For example, you could claim that a request has a particular query parameter like so:

    Spec.Http.observeRequests (Spec.Http.Route.route "GET" <| Matching "fake\\.com")
      |> Spec.expect (Spec.Claim.isListWhere
        [ Spec.Http.url
            Spec.Claim.isStringContaining 1 "sport=bowling"
        ]
      )

This claims makes the most sense when observing requests that match a route
defined with a regular expression, as in the example above.

-}
url : Claim String -> Claim HttpRequest
url claim =
  \(HttpRequest request) ->
    claim request.url
