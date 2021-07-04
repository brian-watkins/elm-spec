module Spec.Http exposing
  ( HttpRequest
  , HttpRequestDataAssertion
  , logRequests
  , observeRequests
  , clearRequestHistory
  , header
  , body
  , bodyPart
  , asText
  , asJson
  , asFile
  , Blob
  , asBlob
  , url
  )

{-| Observe, and make claims about HTTP requests during a spec.

Here's an example:

First, create an [HttpResponseStub](Spec.Http.Stub#HttpResponseStub) that defines the response to return
when a request is sent by the program.

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
              [ Spec.Http.body
                  (Spec.Http.asJson <|
                    Json.field "name" Json.string)
                  (Spec.Claim.isEqual Debug.toString "bowling")
              ]
            )
        )
      )
    ]

# Observe HTTP Requests
@docs HttpRequest, observeRequests, clearRequestHistory

# Make Claims About HTTP Requests
@docs url, header, body, bodyPart, HttpRequestDataAssertion, asText, asJson, asFile, Blob, asBlob

# Debug
@docs logRequests

-}

import Spec.Observer as Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Claim as Claim exposing (Claim, Verdict)
import Spec.Report as Report exposing (Report)
import Spec.Message as Message exposing (Message)
import Spec.Http.Route as Route exposing (HttpRoute)
import Spec.Http.Request as Request
import Spec.Step as Step
import Spec.Step.Command as Command
import Json.Decode as Json
import Dict
import File exposing (File)
import Bytes exposing (Bytes)




{-| Represents an HTTP request made by the program in the course of the scenario.
-}
type HttpRequest
  = HttpRequest Request.HttpRequest


{-| Asserts that an HTTP request body (or part of that body) is data of a certain type.
-}
type HttpRequestDataAssertion a
  = HttpRequestDataAssertion
      { dataType: String
      , transformer: (Request.HttpRequestData -> TransformerResult a)
      }


type TransformerResult a
  = Transformed a
  | WrongType String
  | BadValue Report


{-| Claim that an HTTP request has a header that satisfies the given claim.

For example, if the observed request has an `Authorization` header with the value
`Bearer some-fun-token`, then the following claim would be accepted:

    Spec.Http.header "Authorization" <|
      Spec.Claim.isSomethingWhere <|
      Spec.Claim.isStringContaining 1 "some-fun-token"

Note that HTTP header names are case-insensitive, so the capitalization of the first argument
doesn't matter.

-}
header : String -> Claim (Maybe String) -> Claim HttpRequest
header name claim =
  \(HttpRequest request) ->
    Dict.get (String.toLower name) request.headers
      |> claim
      |> Claim.mapRejection (\report -> Report.batch
        [ Report.fact "Claim rejected for header" name
        , report
        , Report.fact "The request actually had these headers" <| Request.headersToString "\n" request
        ]
      )


{-| Claim that an HTTP request has a body with data that satisfies the given claim.

For example, if the body of the observed request were `{"sport":"bowling"}`,
then the following claim would be accepted:

    Spec.Http.body
      (Spec.Http.asJson <|
        Json.Decode.field "sport" Json.Decode.string)
      (Spec.Claim.isEqual Debug.toString "bowling")
 
-}
body : HttpRequestDataAssertion a -> Claim a -> Claim HttpRequest
body (HttpRequestDataAssertion { dataType, transformer }) claim =
  \(HttpRequest request) ->
    case request.body of
      Request.Multipart _ ->
        Claim.Reject <| Report.fact "Claim rejected for request body" "The request has a multipart body.\nUse Spec.Http.bodyPart to make a claim about the request body."
      _ ->
        case transformer request.body of
          Transformed value ->
            claim value
              |> Claim.mapRejection (\report -> Report.batch
                [ Report.note <| "Claim rejected for " ++ dataType
                , report
                ]
              )
          WrongType err ->
            Claim.Reject <| Report.fact ("Claim rejected for " ++ dataType) err
          BadValue report ->
            Claim.Reject report


{-| Claim that an HTTP request has a multipart body with a named part that satisfies the given claim.

There can be multiple parts, all with the same name. They should all be the same type of data.

For example, if the observed request had a multipart body with a part called `image` that contains a file
named `fun-image.png`, then the following claim would be accepted:

    Spec.Http.bodyPart "image" Spec.Http.asFile <|
      Spec.Claim.isListWhere
        [ Spec.Claim.specifyThat File.name <|
            Spec.Claim.isEqual Debug.toString "fun-image.png"
        ]

-}
bodyPart : String -> HttpRequestDataAssertion a -> Claim (List a) -> Claim HttpRequest
bodyPart name (HttpRequestDataAssertion { dataType, transformer }) claim =
  \(HttpRequest request) ->
    case request.body of
      Request.Multipart parts ->
        List.filter (\part -> part.name == name) parts
          |> List.map .data
          |> List.map transformer
          |> tryToCollectValues name dataType
          |> Result.map claim
          |> Result.map (Claim.mapRejection (\report -> Report.batch
              [ Report.note <| "Claim rejected for " ++ dataType ++ " in body part: " ++ name
              , report
              ]
          ))
          |> toVerdict
      _ ->
        Claim.Reject <| Report.fact ("Claim rejected for " ++ dataType ++ " in body part: " ++ name) "The request does not have a multipart body.\nUse Spec.Http.body to make a claim about the request body."


tryToCollectValues : String -> String -> List (TransformerResult a) -> Result Report (List a)
tryToCollectValues name dataType =
  List.foldl (\result collectionResult ->
    case collectionResult of
      Ok soFar ->
        case result of
          Transformed value ->
            Ok <| List.append soFar [ value ]
          WrongType msg ->
            Err <| Report.fact ("Claim rejected for " ++ dataType ++ " in body part: " ++ name) msg
          BadValue errorReport ->
            Err errorReport
      Err report ->
        Err report
  ) (Ok [])


toVerdict : Result Report Verdict -> Verdict
toVerdict result =
  case result of
    Ok verdict ->
      verdict
    Err report ->
      Claim.Reject report


{-| Claim that some HTTP request data is text that satisfies the given claim.

Note: If you create a request with `Http.emptyBody` then the given claim will be evaluated
against the empty string.
-}
asText : HttpRequestDataAssertion String
asText =
  HttpRequestDataAssertion
    { dataType = "text data"
    , transformer = \requestData ->
        case requestData of
          Request.NoData ->
            Transformed ""
          Request.TextData actual ->
            Transformed actual
          Request.FileData _ ->
            WrongType "The request data is a file."
          Request.BinaryData _ ->
            WrongType "The request data is binary. Use Spec.Http.binaryData instead."
          Request.Multipart _ ->
            WrongType "The request data is multipart."  
    }


{-| Claim that some HTTP request data is text that can be decoded with the
given JSON decoder into a value that satisfies the given claim.

For example, if the body of the observed request were `{"sport":"bowling"}`,
then the following claim would be accepted:

    Spec.Http.body
      (Spec.Http.asJson <|
        Json.Decode.field "sport" Json.Decode.string)
      (Spec.Claim.isEqual Debug.toString "bowling")

-}
asJson : Json.Decoder a -> HttpRequestDataAssertion a
asJson decoder =
  HttpRequestDataAssertion
    { dataType = "JSON data"
    , transformer = \requestData ->
        case requestData of
          Request.TextData actual ->
            case Json.decodeString decoder actual of
              Ok value ->
                Transformed value
              Err error ->
                BadValue <| Report.batch
                  [ Report.fact "Expected to decode request data as JSON" actual
                  , Report.fact "but the decoder failed" <| Json.errorToString error
                  ]
          Request.NoData ->
            WrongType "It has no data at all."
          Request.FileData _ ->
            WrongType "The request data is a file."
          Request.BinaryData _ ->
            WrongType "The request data is binary. Use Spec.Http.binaryData instead."
          Request.Multipart _ ->
            WrongType "The request data is multipart."
    }


{-| Claim that some HTTP request data is a `File` that satisfies the given claim.

For example, if the body of an observed request is a `File` with the name `funFile.txt`, then the
following claim would be accepted:

    Spec.Http.body Spec.Http.asFile
      <| Spec.Claim.specifyThat File.name
      <| Claim.isStringContaining 1 "funFile.txt"

-}
asFile : HttpRequestDataAssertion File
asFile =
  HttpRequestDataAssertion
    { dataType = "file data"
    , transformer = \requestData ->
        case requestData of
          Request.FileData file ->
            Transformed file
          Request.NoData ->
            WrongType "It has no data at all."
          Request.BinaryData _ ->
            WrongType "The request data is binary. Use Spec.Http.binaryData instead."
          Request.TextData _ ->
            WrongType "The request data is text."
          Request.Multipart _ ->
            WrongType "The request data is multipart."  
    }


{-| When `Bytes` are sent as the HTTP request body or as part of the HTTP request body, a MIME type
must be specified. This value groups `Bytes` together with their associated MIME type.
-}
type alias Blob =
  { mimeType: String
  , data: Bytes
  }


{-| Claim that some HTTP request data is a `Blob` that satisfies the given claim.

For example, if the body of an observed request is binary data with a width of 12, then the
following claim would be accepted:

    Spec.Http.body Spec.Http.binaryData
      <| Spec.Claim.specifyThat .data
      <| Spec.Claim.specifyThat Bytes.width
      <| Claim.isEqual Debug.toString 12

-}
asBlob : HttpRequestDataAssertion Blob
asBlob =
  HttpRequestDataAssertion
    { dataType = "binary data"
    , transformer = \requestData ->
        case requestData of
          Request.BinaryData blob ->
            Transformed blob
          Request.NoData ->
            WrongType "It has no data at all."
          Request.TextData _ ->
            WrongType "The request data is text."
          Request.FileData _ ->
            WrongType "The request data is a file."
          Request.Multipart _ ->
            WrongType "The request data is multipart."
    }


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
  Observer.inquire (fetchRequestsFor route) (\message ->
    Message.decode (Json.list <| Json.map HttpRequest Request.decoder) message
      |> Result.withDefault []
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


{-| A step that clears the history of HTTP requests received.

Any HTTP requests made prior to executing this step will not be observed.

It can be useful to clear the HTTP request history when a scenario results in
many HTTP requests, but you care about observing only those that occur
after a certain point.
-}
clearRequestHistory : Step.Step model msg
clearRequestHistory =
  \_ ->
    Command.sendMessage <| Message.for "_http" "clear-history"


{-| A step that logs to the console any HTTP requests received prior to executing this step.

You might use this step to help debug a rejected observation.
-}
logRequests : Step.Step model msg
logRequests =
  \_ ->
    fetchRequestsFor (Route.route "ANY" <| Route.Matching ".+")
      |> Command.sendRequest andThenLogRequests


andThenLogRequests : Message -> Step.Command msg
andThenLogRequests message =
  Message.decode (Json.list Request.decoder) message
    |> Result.map (Command.log << Request.toReport)
    |> Result.withDefault (Command.log <| Report.note "Unable to decode HTTP requests!")


{-| Claim that the url of an HTTP request satisfies the given claim.

In the example below, we claim that there is one `GET` request to a url containing
`fake.com` and that url has the query parameter `sport=bowling`.

    Spec.Http.observeRequests (Spec.Http.Route.route "GET" <| Matching "fake\\.com")
      |> Spec.expect (Spec.Claim.isListWhere
        [ Spec.Http.url <|
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
